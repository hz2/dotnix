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
        inherit ((pkgs.formats.toml { })) type;
        default = { };
        description = "Extra languages.toml fields for this language.";
      };
    };
  };

  # helix's own languages.toml REPLACES language-servers per language, so a
  # language kept at languageServers = null (upstream default) can't just be
  # appended to; appending needs the upstream default list, which depends on
  # the helix version. these are the lists helix 25.07.1's languages.toml
  # sets for the languages this module leaves at null below. a language
  # outside this map with wordCompletion/ai enabled trips the assertion below
  # instead of silently dropping upstream's servers; add it here to fix.
  upstreamServers = {
    rust = [ "rust-analyzer" ];
    c = [ "clangd" ];
    cpp = [ "clangd" ];
    lua = [ "lua-language-server" ];
    bash = [ "bash-language-server" ];
  };

  appendServers =
    name: l: extra:
    if extra == [ ] then
      l.languageServers
    else
      let
        base = if l.languageServers != null then l.languageServers else upstreamServers.${name} or [ ];
      in
      lib.unique (base ++ extra);

  # languages that would need an append (wordCompletion/ai enabled for them)
  # but are stuck at languageServers = null with no known upstream default
  languagesMissingUpstreamServers = lib.attrNames (
    lib.filterAttrs (
      name: l:
      l.languageServers == null
      && !(upstreamServers ? ${name})
      && (cfg.wordCompletion.enable || (cfg.ai.enable && lib.elem name cfg.ai.languages))
    ) cfg.languages
  );

  renderLanguage =
    name: l:
    let
      extra =
        lib.optional cfg.wordCompletion.enable "scls"
        ++ lib.optional (cfg.ai.enable && lib.elem name cfg.ai.languages) "lsp-ai";
      servers = appendServers name l extra;
    in
    {
      inherit name;
      auto-format = cfg.autoFormat;
    }
    // lib.optionalAttrs (servers != null) { language-servers = servers; }
    // lib.optionalAttrs (l.formatter != null) { inherit (l) formatter; }
    // l.extraConfig;

  # fixed env var name lsp-ai reads the key from; the wrapper below exports
  # it from apiKeyFile at run time, so the key never touches the store.
  lspAiAuthTokenEnvVar = "LSP_AI_API_KEY";

  # nix doesn't expand ~, and quoting it for the shell below would stop bash
  # from expanding it either, so expand against home.homeDirectory here.
  expandHome =
    path:
    if lib.hasPrefix "~/" path then
      "${config.home.homeDirectory}/${lib.removePrefix "~/" path}"
    else
      path;

  # execs lsp-ai after optionally exporting the key read from apiKeyFile;
  # keeps the key out of the nix store (only the file path is a store input).
  lspAiWrapper = pkgs.writeShellScript "lsp-ai-wrapper" ''
    set -eu
    ${lib.optionalString (cfg.ai.apiKeyFile != null) ''
      export ${lspAiAuthTokenEnvVar}="$(cat ${lib.escapeShellArg (expandHome cfg.ai.apiKeyFile)})"
    ''}
    exec ${lib.getExe pkgs.lsp-ai} "$@"
  '';

  languageServers =
    lib.optionalAttrs cfg.wordCompletion.enable {
      scls = {
        command = lib.getExe pkgs.simple-completion-language-server;
        # feature_words is the point of wordCompletion; snippets/paths left
        # off by default (see the project's README for the full option list,
        # there is no max_completion_items option upstream).
        config = {
          feature_words = true;
          feature_snippets = true;
          feature_paths = false;
          feature_unicode_input = false;
          feature_citations = false;
          snippets_first = true;
          case_sensitive = false;
        };
      };
    }
    // lib.optionalAttrs cfg.ai.enable {
      lsp-ai = {
        command = "${lspAiWrapper}";
        config = {
          memory.file_store = { };
          models.model1 = {
            type = "open_ai";
            chat_endpoint = "${cfg.ai.endpoint}/chat/completions";
            inherit (cfg.ai) model;
            # read at runtime, either from apiKeyFile via the wrapper above or
            # from the caller's shell (e.g. fish: set -gx LSP_AI_API_KEY (cat ...)).
            auth_token_env_var_name = lspAiAuthTokenEnvVar;
          };
          completion = {
            model = "model1";
            parameters = {
              max_tokens = 256;
              max_context = 2048;
              # <CURSOR>/{CODE} match lsp-ai's own helix example; see
              # SilasMarvin/lsp-ai examples/helix/openai-chat-code-completion.toml
              messages = [
                {
                  role = "system";
                  content = ''
                    Instructions:
                    - You are an AI programming assistant.
                    - Given a piece of code with the cursor location marked by "<CURSOR>", replace "<CURSOR>" with the correct code or comment.
                    - Only respond with code or comments.
                    - Only replace "<CURSOR>"; do not include any previously written code.
                    - Never include "<CURSOR>" in your response.
                  '';
                }
                {
                  role = "user";
                  content = "{CODE}";
                }
              ];
            };
          };
        };
      };
    };
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
    wordCompletion = {
      enable = lib.mkEnableOption ''
        buffer word/snippet completion via simple-completion-language-server
        (scls), appended to every configured language's servers
      '';
    };
    ai = {
      enable = lib.mkEnableOption "code completion via lsp-ai against an OpenAI-compatible endpoint";
      endpoint = lib.mkOption {
        type = lib.types.str;
        example = "http://127.0.0.1:8000/v1";
        description = "Base URL; /chat/completions is appended for the request.";
      };
      model = lib.mkOption {
        type = lib.types.str;
        description = "Model id sent to the endpoint.";
      };
      apiKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "~/.config/hive/local-key";
        description = ''
          Path read at hx startup and exported as LSP_AI_API_KEY; never put
          the key itself here. When null, export LSP_AI_API_KEY yourself
          before starting hx (e.g. fish: set -gx LSP_AI_API_KEY (cat ~/.config/hive/local-key)).
        '';
      };
      languages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "rust"
          "nix"
          "python"
          "go"
          "bash"
        ];
        description = "Helix language names lsp-ai is appended to.";
      };
    };
    settings = lib.mkOption {
      inherit ((pkgs.formats.toml { })) type;
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

    assertions = [
      {
        assertion = languagesMissingUpstreamServers == [ ];
        message = ''
          dotnix.editors.helix: languages.${lib.concatStringsSep ", " languagesMissingUpstreamServers} have languageServers = null (upstream default) with no known upstream
          server list to append scls/lsp-ai to; set languageServers explicitly.
        '';
      }
    ];

    programs.helix = {
      enable = true;
      inherit (cfg) defaultEditor;
      extraPackages =
        lib.unique (lib.concatMap (l: l.packages) (lib.attrValues cfg.languages))
        ++ lib.optional cfg.wordCompletion.enable pkgs.simple-completion-language-server
        ++ lib.optional cfg.ai.enable pkgs.lsp-ai;
      languages = {
        language = lib.mapAttrsToList renderLanguage cfg.languages;
      }
      // lib.optionalAttrs (languageServers != { }) { language-server = languageServers; };

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
