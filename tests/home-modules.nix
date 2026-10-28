{
  pkgs,
  self,
  inputs,
}:
# eval-only checks for dotnix home modules: render configs and assert on them,
# no vm or home activation needed
let
  inherit (pkgs) lib;

  hmModule = module: {
    imports = [
      self.homeModules.default
      module
    ];
    dotnix.user.name = "test";
    home.stateVersion = "24.11";
  };

  hm =
    module:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ (hmModule module) ];
    }).config;

  # homeManagerConfiguration throws on failed assertions, so evaluate the raw
  # module set to inspect them
  hmUnchecked =
    module:
    let
      hmLib = import "${inputs.home-manager}/modules/lib/stdlib-extended.nix" lib;
    in
    (hmLib.evalModules {
      modules = [
        (hmModule module)
      ]
      ++ import "${inputs.home-manager}/modules/modules.nix" {
        inherit pkgs;
        lib = hmLib;
      };
      class = "homeManager";
      specialArgs.modulesPath = "${inputs.home-manager}/modules";
    }).config;

  failedAssertions = cfg: map (a: a.message) (lib.filter (a: !a.assertion) cfg.assertions);

  pi = hm {
    dotnix.ai.pi = {
      enable = true;
      providers.local = {
        baseUrl = "http://127.0.0.1:8000/v1";
        api = "openai-completions";
        apiKey = "!cat /run/key";
        models.a = {
          name = "A";
          contextWindow = 1000;
          maxTokens = 1000;
        };
        models.b = {
          name = "B";
          contextWindow = 2000;
          maxTokens = 100;
          extraConfig.compat.supportsReasoningEffort = false;
        };
      };
      extensions.vim = null;
      contextFiles.Notes = "~/notes.md";
    };
    dotnix.ai.web.enable = true;
  };
  piModels = builtins.fromJSON pi.home.file.".pi/agent/models.json".text;
  piProvider = piModels.providers.local;
  piFiles = lib.attrNames pi.home.file;

  piBad = hmUnchecked {
    dotnix.ai.pi = {
      enable = true;
      providers.x = {
        baseUrl = "http://x";
        api = "openai-completions";
        models.too-big = {
          name = "too big";
          contextWindow = 10;
          maxTokens = 11;
        };
      };
    };
  };

  skills = hm {
    dotnix.ai.skills = {
      enable = true;
      targets.codex = false;
      skills.demo = ../config/skills/web-research;
    };
  };
  skillFiles = lib.attrNames skills.home.file;

  helix = hm { dotnix.editors.helix.enable = true; };
  helixLangs = lib.listToAttrs (
    map (l: lib.nameValuePair l.name l) helix.programs.helix.languages.language
  );

  checks = {
    "pi renders provider" = piProvider.baseUrl == "http://127.0.0.1:8000/v1";
    "pi keeps command api key" = piProvider.apiKey == "!cat /run/key";
    "pi renders every model" =
      lib.sort lib.lessThan (map (m: m.id) piProvider.models) == [
        "a"
        "b"
      ];
    "pi model extraConfig merges" =
      (lib.findFirst (m: m.id == "b") null piProvider.models).compat.supportsReasoningEffort == false;
    "pi default theme" = pi.dotnix.ai.pi.settings.theme == "nord";
    "pi null extension is dropped" = !(lib.elem ".pi/agent/extensions/vim.ts" piFiles);
    "pi builtin extension stays" = lib.elem ".pi/agent/extensions/handoff.ts" piFiles;
    "pi directory extension" = lib.elem ".pi/agent/extensions/plan-mode" piFiles;
    "pi context list" =
      builtins.fromJSON pi.home.file.".pi/agent/extensions/context/context-files.json".text == [
        {
          label = "Notes";
          path = "~/notes.md";
        }
      ];
    "web adds pi tool" = lib.elem ".pi/agent/extensions/web.ts" piFiles;
    "web adds skill when skills off" = !(lib.elem ".claude/skills/web-research" piFiles);
    "pi valid config has no failed assertions" = failedAssertions pi == [ ];
    "pi rejects maxTokens over contextWindow" = lib.any (lib.hasInfix "too-big") (
      failedAssertions piBad
    );

    "skills go to claude" = lib.elem ".claude/skills/demo" skillFiles;
    "skills go to pi" = lib.elem ".pi/agent/skills/demo" skillFiles;
    "skills skip disabled codex" = !(lib.elem ".codex/skills/demo" skillFiles);
    "skills skip opencode by default" = !(lib.elem ".config/opencode/skills/demo" skillFiles);

    "helix nix formatter" = helixLangs.nix.formatter.command == "nixfmt";
    "helix python formatter" =
      helixLangs.python.formatter.args == [
        "format"
        "-"
      ];
    "helix keeps upstream c servers" = !(helixLangs.c ? language-servers);
    "helix no format on save" = !helixLangs.rust.auto-format;
    "helix ctrl-h window nav" = helix.programs.helix.settings.keys.normal.C-h == "jump_view_left";
    "helix ships formatter packages" = lib.elem pkgs.nixfmt helix.programs.helix.extraPackages;
  };

  failed = lib.attrNames (lib.filterAttrs (_: ok: !ok) checks);
in
assert lib.assertMsg (
  failed == [ ]
) "home-modules checks failed: ${lib.concatStringsSep ", " failed}";
pkgs.runCommand "home-modules-eval" { } "touch $out"
