{ pkgs, ... }:

let
  git-status = pkgs.writeShellScript "tmux-git-status" ''
    cd "''${1:-$PWD}" 2>/dev/null || exit 0
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      branch=$(git branch --show-current 2>/dev/null)
      git_status=$(git status --porcelain 2>/dev/null)

      modified=$(echo "$git_status" | grep -c "^ M" || true)
      staged=$(echo "$git_status"   | grep -c "^M"  || true)
      untracked=$(echo "$git_status"| grep -c "^??" || true)

      output=" $branch"

      if [ -n "$git_status" ]; then
        total=$(echo "$git_status" | wc -l | tr -d ' ')
        status_parts=""
        [ "$modified"  -gt 0 ] && status_parts="''${status_parts}~''${modified}"
        [ "$staged"    -gt 0 ] && status_parts="''${status_parts}+''${staged}"
        [ "$untracked" -gt 0 ] && status_parts="''${status_parts}?''${untracked}"
        [ -n "$status_parts" ] && output="''${output} ''${total} [''${status_parts}]"
      fi

      echo "$output"
    fi
  '';

nix-status = pkgs.writeShellScript "tmux-nix-status" ''
    if [ -n "$IN_NIX_SHELL" ]; then
      if [ -n "$name" ]; then
        echo "● $name"
      else
        echo "● nix"
      fi
    fi
  '';

  notify-status = pkgs.writeShellScript "tmux-notify-status" ''
    notif_file="$HOME/.local/state/notifications.tsv"
    if [ ! -f "$notif_file" ] || [ ! -s "$notif_file" ]; then exit 0; fi

    count=$(wc -l < "$notif_file")
    latest=$(tail -1 "$notif_file" | cut -f3 | cut -c1-40)

    if [ "$count" -eq 1 ]; then
      echo "#[fg=colour196,bold]▲ ''${latest}#[default] "
    else
      echo "#[fg=colour196,bold]▲ ''${count} alerts#[default] "
    fi
  '';

  system-resources = pkgs.writeShellScript "tmux-system-resources" ''
    load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    mem=$(free -h | awk '/Mem:/ {printf "%s/%s", $3, $2}')
    echo " ''${load} ● ''${mem}"
  '';

  time-display = pkgs.writeShellScript "tmux-time-display" ''
    pdt=$(TZ="${pkgs.tzdata}/share/zoneinfo/America/Los_Angeles" date "+%H:%M")
    utc=$(date -u "+%H:%M")
    ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
    echo "''${pdt} PDT | ''${utc} UTC | ''${ip:-N/A}"
  '';

in
{
  programs.tmux = {
    enable       = true;
    prefix       = "C-a";
    mouse        = true;
    baseIndex    = 1;
    escapeTime   = 0;
    historyLimit = 50000;
    keyMode      = "vi";
    terminal     = "tmux-256color";

    extraConfig = ''
      set -ag terminal-overrides ",tmux-256color:RGB"

      bind | split-window -h
      bind % split-window -h
      bind - split-window -v
      bind '"' split-window -v

      bind c new-window

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded"

      set -g renumber-windows on

      # Status bar — bottom, nordfox palette
      set -g status-position  bottom
      set -g status-interval  5
      set -g status-style     "bg=colour235,fg=colour252"

      set -g status-left        "#[bg=colour110,fg=colour235,bold] #S #[bg=colour235,fg=colour110] "
      set -g status-left-length 30

      set -g status-right        "#(${nix-status})#[fg=colour59]│ #[fg=colour150]#(${git-status} #{pane_current_path}) #[fg=colour59]│ #[fg=colour252]#(${system-resources}) #[fg=colour59]│ #[fg=colour116]#(${notify-status})#[fg=colour252]#(${time-display})"
      set -g status-right-length 200

      set -g window-status-format         "#[fg=colour59] #I:#W "
      set -g window-status-current-format "#[bg=colour237,fg=colour252,bold] #I:#W "

      set -g pane-border-style        "fg=colour237"
      set -g pane-active-border-style "fg=colour110"
      set -g message-style            "bg=colour237,fg=colour252"

      bind -T copy-mode-vi v               send-keys -X begin-selection
      bind -T copy-mode-vi y               send-keys -X copy-pipe-and-cancel "wl-copy"
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "wl-copy"
    '';
  };
}
