{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.git;
  user = config.dotnix.user;
in
{
  options.dotnix.git = {
    enable = lib.mkEnableOption "git with delta, libsecret and sane defaults";
    userName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = if user.fullName != null then user.fullName else user.name;
      defaultText = lib.literalExpression "dotnix.user.fullName or dotnix.user.name";
      description = "Commit author name.";
    };
    userEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = user.email;
      defaultText = lib.literalExpression "dotnix.user.email";
      description = "Commit author email.";
    };
    editor = lib.mkOption {
      type = lib.types.str;
      default = "nvim";
      description = "core.editor; also drives the merge tool when it is nvim.";
    };
    identities = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            gitdir = lib.mkOption {
              type = lib.types.str;
              example = "~/oss/";
              description = "Directory prefix the identity applies under.";
            };
            name = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            email = lib.mkOption { type = lib.types.str; };
          };
        }
      );
      default = [ ];
      description = "Per-directory author identities, e.g. personal identity under ~/oss on a work box.";
    };
    sendEmail = {
      enable = lib.mkEnableOption "git send-email over smtp (password from the keyring)";
      smtpServer = lib.mkOption {
        type = lib.types.str;
        default = "smtp.gmail.com";
      };
      smtpServerPort = lib.mkOption {
        type = lib.types.port;
        default = 587;
      };
      smtpUser = lib.mkOption { type = lib.types.str; };
      from = lib.mkOption { type = lib.types.str; };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      package = pkgs.gitFull; # includes git-send-email and libsecret credential helper
      lfs.enable = true;

      includes = map (id: {
        condition = "gitdir:${id.gitdir}";
        contents.user = {
          inherit (id) email;
        }
        // lib.optionalAttrs (id.name != null) { inherit (id) name; };
      }) cfg.identities;

      settings = lib.mkMerge [
        {
          user = lib.filterAttrs (_: v: v != null) {
            name = cfg.userName;
            email = cfg.userEmail;
          };

          init.defaultBranch = "main";
          pull.rebase = true;

          http.postBuffer = 524288000; # 500 MB

          core = {
            inherit (cfg) editor;
            autocrlf = "input";
            safecrlf = true;
            pager = "delta";
          };

          help.autocorrect = 1;

          diff = {
            algorithm = "patience";
            compactionHeuristic = true;
            colorMoved = "default";
          };

          merge.conflictstyle = "diff3";

          color.ui = true;

          interactive.diffFilter = "delta --color-only";

          alias = {
            c = "commit";
            s = "status";
            lg = "log --oneline";
            last = "log --graph --decorate --oneline --pretty";
            f = "push --force-with-lease";
            sl = "stash list";
          };

          credential.helper = "libsecret";
        }
        (lib.mkIf (cfg.editor == "nvim") {
          merge.tool = "nvim";
          mergetool.nvim.cmd = "nvim -d";
        })
        (lib.mkIf (cfg.editor == "hx") {
          # helix has no diff mode; resolve conflict markers in place
          merge.tool = "hx";
          mergetool.hx.cmd = ''hx "$MERGED"'';
        })
        (lib.mkIf cfg.sendEmail.enable {
          sendemail = {
            inherit (cfg.sendEmail)
              smtpServer
              smtpServerPort
              smtpUser
              from
              ;
            smtpEncryption = "tls";
            confirm = "auto";
            chainReplyTo = false;
            thread = true;
            annotate = true;
            suppresscc = "self";
          };
        })
      ];

      ignores = [
        ".direnv"
        ".DS_Store"
        "*.swp"
        "*.swo"
        ".envrc"
      ];
    };

    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" ];
    };

    home.packages = [
      pkgs.delta
      pkgs.libsecret
    ];
  };
}
