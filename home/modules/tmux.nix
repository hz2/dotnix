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

  # continuum's autosave hooks into status-right, which we overwrite below, so re-add its save script there
  continuum-save = "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/scripts/continuum_save.sh";

  # du over the whole store is too slow to run on every status-interval tick, so cache it for 15 min
  nix-store-size = pkgs.writeShellScript "tmux-nix-store-size" ''
    cache="$HOME/.cache/tmux-nix-store-size"
    now=$(date +%s)
    ts=0

    if [ -f "$cache" ]; then
      read -r ts size < "$cache"
    fi

    if [ -z "$size" ] || [ $((now - ts)) -gt 900 ]; then
      size=$(du -sh /nix/store 2>/dev/null | cut -f1)
      echo "$now $size" > "$cache"
    fi

    echo " store ''${size}"
  '';

  sessionizer = pkgs.writeShellScript "tmux-sessionizer" ''
    selected=$(
      {
        find "$HOME/srcs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
        find "$HOME/workspaces" -mindepth 1 -maxdepth 2 -type d -not -path '*/.*' 2>/dev/null
      } | ${pkgs.fzf}/bin/fzf
    )
    [ -z "$selected" ] && exit 0

    # tmux uses . and : as target separators, so sanitize the session name
    name=$(basename "$selected" | tr '.:' '__')

    if ! tmux has-session -t "=$name" 2>/dev/null; then
      tmux new-session -d -s "$name" -c "$selected"
    fi
    tmux switch-client -t "=$name"
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

    # resurrect + continuum restore pane layout/cwd/scrollback on restart, but do not resume a live agent process that was running in a pane
    plugins = [
      {
        plugin = pkgs.tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = pkgs.tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];

    extraConfig = ''
      set -ag terminal-overrides ",tmux-256color:RGB"

      bind | split-window -h
      bind % split-window -h
      bind - split-window -v
      bind '"' split-window -v

      bind c new-window

      # fzf across ~/srcs and ~/workspaces, then switch to (or create) a session per dir
      bind f display-popup -E "${sessionizer}"

      # broadcast input to every pane at once, for prompting several agent panes together
      bind e set-window-option synchronize-panes \; display-message "synchronize-panes #{?synchronize-panes,on,off}"

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

      # leading conditional shows a bold red SYNC tag while broadcasting; #(continuum-save) drives autosave
      # note: chained single-attribute #[] blocks, not one #[a,b,c] block - a comma inside a
      # #{?cond,true,false} branch gets parsed as another branch separator and truncates the string
      set -g status-right        "#{?synchronize-panes,#[bg=colour196]#[fg=colour235]#[bold] SYNC #[default],}#(${continuum-save})#(${nix-status})#[fg=colour59]│ #[fg=colour252]#(${nix-store-size}) #[fg=colour59]│ #[fg=colour150]#(${git-status} #{pane_current_path}) #[fg=colour59]│ #[fg=colour252]#(${system-resources}) #[fg=colour59]│ #[fg=colour116]#(${notify-status})#[fg=colour252]#(${time-display})"
      set -g status-right-length 200

      set -g window-status-format         "#[fg=colour59] #I:#W#F "
      set -g window-status-current-format "#[bg=colour237,fg=colour252,bold] #I:#W#F "

      # flag a window when its panes go silent, e.g. an agent finished and is now idle
      setw -g monitor-silence 30
      set -g window-status-activity-style "bg=colour116,fg=colour235,bold"

      set -g pane-border-style        "fg=colour237"
      set -g pane-active-border-style "fg=colour110"
      set -g message-style            "bg=colour237,fg=colour252"

      bind -T copy-mode-vi v               send-keys -X begin-selection
      bind -T copy-mode-vi y               send-keys -X copy-pipe-and-cancel "wl-copy"
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "wl-copy"
    '';
  };
}
