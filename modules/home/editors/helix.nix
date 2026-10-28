{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.editors.helix;

  formatterType = lib.types.submodule {
    options = {
      command = lib.mkOption { type = lib.types.str; };
      args = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };

  languageType = lib.types.submodule {
    options = {
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Servers and formatters put on helix's PATH only.";
      };
      languageServers = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "Overrides helix's server list for the language; null keeps upstream's.";
      };
      formatter = lib.mkOption {
        type = lib.types.nullOr formatterType;
        default = null;
        description = "External formatter; null falls back to lsp formatting.";
      };
      extraConfig = lib.mkOption {
        type = (pkgs.formats.toml { }).type;
        default = { };
        description = "Extra languages.toml fields for this language.";
      };
    };
  };

  renderLanguage =
    name: l:
    {
      inherit name;
      auto-format = cfg.autoFormat;
    }
    // lib.optionalAttrs (l.languageServers != null) { language-servers = l.languageServers; }
    // lib.optionalAttrs (l.formatter != null) { inherit (l) formatter; }
    // l.extraConfig;
in
{
  options.dotnix.editors.helix = {
    enable = lib.mkEnableOption "helix with language servers and formatters";
    defaultEditor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set EDITOR and VISUAL to hx.";
    };
    theme = lib.mkOption {
      type = lib.types.str;
      default = "nord";
    };
    autoFormat = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Format on save. Off by default; format explicitly with space =.";
    };
    languages = lib.mkOption {
      type = lib.types.attrsOf languageType;
      default = { };
      description = "Per-language servers and formatters, keyed by helix language name.";
    };
    settings = lib.mkOption {
      type = (pkgs.formats.toml { }).type;
      default = { };
      description = "Merged over the dotnix defaults in config.toml.";
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.editors.helix.languages = lib.mapAttrs (_: lib.mkDefault) {
      # rust-analyzer and rustfmt come from rustup per project (rust-toolchain.toml)
      rust = { };
      nix = {
        packages = [
          pkgs.nil
          pkgs.nixfmt
        ];
        languageServers = [ "nil" ];
        formatter.command = "nixfmt";
      };
      c.packages = [ pkgs.clang-tools ];
      cpp.packages = [ pkgs.clang-tools ];
      lua = {
        packages = [
          pkgs.lua-language-server
          pkgs.stylua
        ];
        formatter = {
          command = "stylua";
          args = [ "-" ];
        };
      };
      python = {
        packages = [
          pkgs.basedpyright
          pkgs.ruff
        ];
        languageServers = [
          "basedpyright"
          "ruff"
        ];
        formatter = {
          command = "ruff";
          args = [
            "format"
            "-"
          ];
        };
      };
      go = {
        packages = [ pkgs.gopls ];
        languageServers = [ "gopls" ];
      };
      toml = {
        packages = [ pkgs.taplo ];
        languageServers = [ "taplo" ];
      };
      bash = {
        packages = [
          pkgs.bash-language-server
          pkgs.shfmt
        ];
        formatter = {
          command = "shfmt";
          args = [
            "-i"
            "2"
          ];
        };
      };
      markdown = {
        packages = [ pkgs.marksman ];
        languageServers = [ "marksman" ];
      };
    };

    programs.helix = {
      enable = true;
      inherit (cfg) defaultEditor;
      extraPackages = lib.unique (lib.concatMap (l: l.packages) (lib.attrValues cfg.languages));
      languages.language = lib.mapAttrsToList renderLanguage cfg.languages;

      # helix defaults cover lsp (gd, gr, space k, space r, space a), pickers
      # (space f, space /, space b) and splits (C-w); these only port nvim habits
      settings = lib.recursiveUpdate {
        inherit (cfg) theme;
        editor = {
          line-number = "relative";
          cursorline = true;
          color-modes = true;
          bufferline = "multiple";
          scrolloff = 8;
          true-color = true;
          indent-guides.render = true;
          lsp.display-inlay-hints = true;
          soft-wrap.enable = true;
          end-of-line-diagnostics = "hint";
          inline-diagnostics.cursor-line = "warning";
          file-picker.hidden = false;
          whitespace.render = {
            tab = "all";
            nbsp = "all";
          };
          cursor-shape = {
            insert = "bar";
            select = "underline";
          };
        };
        keys.normal = {
          C-h = "jump_view_left";
          C-j = "jump_view_down";
          C-k = "jump_view_up";
          C-l = "jump_view_right";
          # move line(s), like visual J/K in nvim; goes through the default register
          A-j = [
            "extend_to_line_bounds"
            "delete_selection"
            "paste_after"
          ];
          A-k = [
            "extend_to_line_bounds"
            "delete_selection"
            "move_line_up"
            "paste_before"
          ];
          n = [
            "search_next"
            "align_view_center"
          ];
          N = [
            "search_prev"
            "align_view_center"
          ];
          esc = [
            "collapse_selection"
            "keep_primary_selection"
          ];
          space."=" = ":format";
        };
        keys.select.space."=" = ":format";
      } cfg.settings;
    };
  };
}
