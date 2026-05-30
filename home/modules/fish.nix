{ ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      cat     = "bat";
      grep    = "rg";
      vim     = "nvim";
      vi      = "nvim";
      clauded = "claude --dangerously-skip-permissions";
    };

    shellAbbrs = {
      g   = "git";
      gs  = "git status";
      gd  = "git diff";
      ga  = "git add";
      gc  = "git commit";
      gp  = "git push";
      gl  = "git log --oneline --graph";
      gco = "git checkout";
      gbr = "git branch";
      t   = "tmux";
      ta  = "tmux attach";
      tn  = "tmux new -s";
      tl  = "tmux ls";
    };

    shellInit = ''
      fish_add_path ~/.local/bin ~/.cargo/bin ~/go/bin
    '';

    interactiveShellInit = ''
      set fish_greeting ""
      zoxide init fish | source
      fzf --fish | source
    '';

    functions.bootstrap = {
      body = ''
        argparse 'r/repos=+' 'b/branch=' 'p/path=' -- $argv
        or return 1

        set -l srcs ~/srcs

        # collect repos from flag or fzf
        set -l repos
        if set -q _flag_repos
          for r in $_flag_repos
            for part in (string split ',' $r)
              set -a repos (string trim $part)
            end
          end
        else
          set repos (ls $srcs 2>/dev/null | fzf --multi \
            --prompt="repos > " \
            --header="tab: multi-select  enter: confirm  ctrl-c: cancel" \
            --preview="ls $srcs/{}" \
            --preview-window=right:40%)
          if test -z "$repos"
            echo "no repos selected"
            return 1
          end
        end

        # branch: flag or prompt
        set -l branch
        if set -q _flag_branch
          set branch $_flag_branch
        else
          read -P "branch name: " branch
          if test -z "$branch"
            echo "branch name required"
            return 1
          end
        end

        # destination path: flag or prompt
        set -l dest
        if set -q _flag_path
          set dest $_flag_path
        else
          read -P "destination path: " dest
          if test -z "$dest"
            echo "path required"
            return 1
          end
        end

        set dest (string replace -r '^~' $HOME $dest)
        mkdir -p $dest

        for repo in $repos
          set repo (string trim $repo)
          test -z "$repo"; and continue

          set -l src "$srcs/$repo"
          if not test -d "$src"
            echo "not found: $src"
            continue
          end

          set -l target "$dest/$repo"

          echo ""
          echo "$repo -> $target  (branch: $branch)"

          if git -C $src rev-parse --verify $branch >/dev/null 2>&1
            git -C $src worktree add $target $branch
          else
            git -C $src worktree add -b $branch $target
          end

          if test $status -eq 0
            echo "done: $target"
          else
            echo "failed: $repo"
          end
        end
      '';
    };

    functions.fish_prompt = {
      body = ''
        set -l last_status $status
        set -l cwd (prompt_pwd)

        set_color blue
        echo -n $cwd
        set_color normal

        set -l branch (git branch --show-current 2>/dev/null)
        if test -n "$branch"
          set_color brblack
          echo -n " ("
          set_color yellow
          echo -n $branch

          set -l gs (git status --porcelain 2>/dev/null)
          if test -n "$gs"
            set -l staged    (string match -r '^[MADRCU]' -- $gs)
            set -l modified  (string match -r '^.[MD]'    -- $gs)
            set -l untracked (string match -r '^\?\?'     -- $gs)
            set -l sc (count $staged)
            set -l mc (count $modified)
            set -l uc (count $untracked)
            echo -n " "
            if test $sc -gt 0
              set_color green
              echo -n "+$sc"
            end
            if test $mc -gt 0
              set_color red
              echo -n "!$mc"
            end
            if test $uc -gt 0
              set_color brblack
              echo -n "?$uc"
            end
          end

          set_color brblack
          echo -n ")"
          set_color normal
        end

        if set -q IN_NIX_SHELL
          set_color cyan
          if set -q name; and test -n "$name"
            echo -n " [nix:$name]"
          else
            echo -n " [nix]"
          end
          set_color normal
        end

        echo -n " "
        if test $last_status -eq 0
          set_color green
        else
          set_color red
        end
        echo -n "λ"
        set_color normal
        echo -n " "
      '';
    };
  };
}
