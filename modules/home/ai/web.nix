{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.ai.web;
  env = lib.filterAttrs (_: v: v != null) {
    DOTNIX_WEB_BACKEND = cfg.backend;
    DOTNIX_WEB_SEARXNG = cfg.searxngUrl;
    DOTNIX_WEB_BRAVE_KEY_CMD = cfg.braveKeyCommand;
    DOTNIX_WEB_MAX_CHARS = toString cfg.maxChars;
  };

  # pi resolves the binary itself, so pin it to the store path
  piExtension = pkgs.replaceVars ../../../config/pi/extensions/web.ts {
    dotnixWeb = lib.getExe cfg.package;
  };
in
{
  options.dotnix.ai.web = {
    enable = lib.mkEnableOption ''
      the dotnix-web search/fetch cli, plus a pi tool and an agent skill for it.
      Useful where built-in agent web tools are missing or blocked
    '';
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.dotnix-web or (pkgs.callPackage ../../../pkgs/dotnix-web/package.nix { });
      defaultText = lib.literalExpression "pkgs.dotnix-web";
    };
    backend = lib.mkOption {
      type = lib.types.enum [
        "duckduckgo"
        "searxng"
        "brave"
      ];
      default = "duckduckgo";
      description = "Search backend. duckduckgo needs no key.";
    };
    searxngUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "http://nipogi:8888";
    };
    braveKeyCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "cat /run/agenix/brave-api-key";
      description = "Shell command printing a brave search api key.";
    };
    maxChars = lib.mkOption {
      type = lib.types.ints.positive;
      default = 20000;
      description = "Cap on fetched page text, to protect agent context.";
    };
    skill = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the web-research skill through dotnix.ai.skills.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.backend != "searxng" || cfg.searxngUrl != null;
        message = "dotnix.ai.web: backend searxng needs searxngUrl";
      }
      {
        assertion = cfg.backend != "brave" || cfg.braveKeyCommand != null;
        message = "dotnix.ai.web: backend brave needs braveKeyCommand";
      }
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."dotnix-web/env".text = lib.concatStrings (
      lib.mapAttrsToList (k: v: "${k}=${lib.escapeShellArg v}\n") env
    );

    dotnix.ai.pi.extensions.web = lib.mkDefault piExtension;
    dotnix.ai.skills.skills.web-research = lib.mkIf cfg.skill (
      lib.mkDefault ../../../config/skills/web-research
    );
  };
}
