{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.ai.pi;
  json = pkgs.formats.json { };

  modelModule =
    { name, ... }:
    {
      options = {
        id = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Model id sent to the provider.";
        };
        name = lib.mkOption {
          type = lib.types.str;
          description = "Display name.";
        };
        reasoning = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        input = lib.mkOption {
          type = lib.types.listOf (
            lib.types.enum [
              "text"
              "image"
            ]
          );
          default = [ "text" ];
        };
        contextWindow = lib.mkOption { type = lib.types.ints.positive; };
        maxTokens = lib.mkOption { type = lib.types.ints.positive; };
        cost = {
          input = lib.mkOption {
            type = lib.types.numbers.nonnegative;
            default = 0;
            description = "USD per million input tokens.";
          };
          output = lib.mkOption {
            type = lib.types.numbers.nonnegative;
            default = 0;
          };
          cacheRead = lib.mkOption {
            type = lib.types.numbers.nonnegative;
            default = 0;
          };
          cacheWrite = lib.mkOption {
            type = lib.types.numbers.nonnegative;
            default = 0;
          };
        };
        extraConfig = lib.mkOption {
          type = json.type;
          default = { };
          description = "Extra model fields merged verbatim, e.g. compat.";
        };
      };
    };

  providerModule = {
    options = {
      baseUrl = lib.mkOption {
        type = lib.types.str;
        example = "http://127.0.0.1:8000/v1";
      };
      api = lib.mkOption {
        type = lib.types.str;
        example = "openai-completions";
        description = "Pi api adapter.";
      };
      apiKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "!cat ~/.config/hive/local-key";
        description = ''
          Key, env var name, or pi's "!command" form. Use the command form so
          real keys never land in the world-readable store.
        '';
      };
      models = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule modelModule);
        default = { };
        description = "Models keyed by id.";
      };
      extraConfig = lib.mkOption {
        type = json.type;
        default = { };
        description = "Extra provider fields merged verbatim, e.g. headers or compat.";
      };
    };
  };

  renderModel =
    m:
    {
      inherit (m)
        id
        name
        reasoning
        input
        contextWindow
        maxTokens
        cost
        ;
    }
    // m.extraConfig;

  renderProvider =
    p:
    {
      inherit (p) baseUrl api;
      models = map renderModel (lib.attrValues p.models);
    }
    // lib.optionalAttrs (p.apiKey != null) { inherit (p) apiKey; }
    // p.extraConfig;

  enabled = lib.filterAttrs (_: v: v != null);

  # a single .ts file becomes <name>.ts, a directory keeps its layout under <name>/
  extensionFiles = lib.mapAttrs' (
    name: src:
    let
      isDir = lib.pathIsDirectory src;
    in
    lib.nameValuePair ".pi/agent/extensions/${name}${lib.optionalString (!isDir) ".ts"}" {
      source = src;
      recursive = isDir;
    }
  ) (enabled cfg.extensions);

  themeFiles = lib.mapAttrs' (
    name: src: lib.nameValuePair ".pi/agent/themes/${name}.json" { source = src; }
  ) (enabled cfg.themes);

  contextList = lib.mapAttrsToList (label: path: { inherit label path; }) cfg.contextFiles;

  allModels = lib.concatMap (
    pname: map (m: m // { provider = pname; }) (lib.attrValues cfg.providers.${pname}.models)
  ) (lib.attrNames cfg.providers);
in
{
  options.dotnix.ai.pi = {
    enable = lib.mkEnableOption "the pi coding agent with dotnix extensions";
    package = lib.mkPackageOption pkgs "pi-coding-agent" { };

    providers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule providerModule);
      default = { };
      description = "Rendered to ~/.pi/agent/models.json.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = json.type;
        options.theme = lib.mkOption {
          type = lib.types.str;
          default = "nord";
        };
      };
      default = { };
      description = "Rendered to ~/.pi/agent/settings.json (defaultProvider, defaultModel, compaction, ...).";
    };

    extensions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.path);
      default = { };
      description = ''
        Extensions keyed by name; a .ts file or a directory with index.ts.
        Built-ins are set with mkDefault; set one to null to drop it.
      '';
    };

    themes = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.path);
      default = { };
      description = "Theme json files keyed by theme name.";
    };

    contextFiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        "Global Claude instructions" = "~/.claude/CLAUDE.md";
      };
      description = ''
        Files appended to every system prompt by the context extension, keyed
        by section label. Missing files are skipped.
      '';
    };

    instructions = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
      default = null;
      description = "Global AGENTS.md for pi.";
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.ai.pi.extensions = {
      vim = lib.mkDefault ../../../config/pi/extensions/vim.ts;
      rg-replace-guard = lib.mkDefault ../../../config/pi/extensions/rg-replace-guard.ts;
      nix-store-scan-guard = lib.mkDefault ../../../config/pi/extensions/nix-store-scan-guard.ts;
      remember = lib.mkDefault ../../../config/pi/extensions/remember.ts;
      plan-mode = lib.mkDefault ../../../config/pi/extensions/plan-mode;
      handoff = lib.mkDefault ../../../config/pi/extensions/handoff.ts;
      context = lib.mkDefault ../../../config/pi/extensions/context;
    };
    dotnix.ai.pi.themes.nord = lib.mkDefault ../../../config/pi/themes/nord.json;

    assertions =
      map (m: {
        assertion = m.maxTokens <= m.contextWindow;
        message = "dotnix.ai.pi.providers.${m.provider}.models.${m.id}: maxTokens exceeds contextWindow";
      }) allModels
      ++ lib.mapAttrsToList (pname: p: {
        assertion = lib.allUnique (map (m: m.id) (lib.attrValues p.models));
        message = "dotnix.ai.pi.providers.${pname}: duplicate model ids";
      }) cfg.providers;

    home.packages = [ cfg.package ];

    home.file =
      extensionFiles
      // themeFiles
      // {
        ".pi/agent/models.json".text = builtins.toJSON {
          providers = lib.mapAttrs (_: renderProvider) cfg.providers;
        };
        ".pi/agent/settings.json".source = json.generate "pi-settings.json" cfg.settings;
      }
      // lib.optionalAttrs (cfg.extensions.context or null != null) {
        ".pi/agent/extensions/context/context-files.json".text = builtins.toJSON contextList;
      }
      // lib.optionalAttrs (cfg.instructions != null) {
        ".pi/agent/AGENTS.md".text = cfg.instructions;
      };
  };
}
