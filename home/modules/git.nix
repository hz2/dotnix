{ pkgs, ... }:

{
  programs.git = {
    enable    = true;
    package   = pkgs.gitFull; # includes git-send-email and libsecret credential helper
    lfs.enable = true;

    settings = {
      user = {
        name  = "jos";
        email = "jsondevers@gmail.com";
      };

      init.defaultBranch = "main";
      pull.rebase        = true;

      http.postBuffer = 524288000; # 500 MB

      core = {
        editor   = "nvim";
        autocrlf = "input";
        safecrlf = true;
        pager    = "delta";
      };

      help.autocorrect = 1;

      diff = {
        algorithm          = "patience";
        compactionHeuristic = true;
        colorMoved         = "default";
      };

      merge = {
        conflictstyle = "diff3";
        tool          = "nvim";
      };

      mergetool.nvim.cmd = "nvim -d";

      color.ui = true;

      interactive.diffFilter = "delta --color-only";

      alias = {
        c    = "commit";
        s    = "status";
        lg   = "log --oneline";
        last = "log --graph --decorate --oneline --pretty";
        f    = "push --force-with-lease";
        sl   = "stash list";
      };

      credential.helper = "libsecret";

      # lkml patch submission via gmail smtp; password stored in gnome-keyring at runtime
      sendemail = {
        smtpServer     = "smtp.gmail.com";
        smtpServerPort = 587;
        smtpEncryption = "tls";
        smtpUser       = "hz2@users.noreply.github.com";
        from           = "Jason Devers <hz2@users.noreply.github.com>";
        confirm        = "auto";
        chainReplyTo   = false;
        thread         = true;
        annotate       = true;
        suppresscc     = "self";
      };
    };

    ignores = [ ".direnv" ".DS_Store" "*.swp" "*.swo" ".envrc" ];
  };

  services.gnome-keyring = {
    enable     = true;
    components = [ "secrets" ];
  };

  home.packages = [ pkgs.delta pkgs.libsecret ];
}
