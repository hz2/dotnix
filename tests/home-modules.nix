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

  claude = hm {
    dotnix.ai.skills = {
      enable = true;
      skills.demo = ../config/skills/web-research;
    };
    dotnix.ai.claude.enable = true;
  };
  claudeFiles = lib.attrNames claude.home.file;

  codex = hm {
    dotnix.ai.skills = {
      enable = true;
      skills.demo = ../config/skills/web-research;
    };
    dotnix.ai.codex.enable = true;
  };
  codexFiles = lib.attrNames codex.home.file;

  fish = hm { dotnix.shell.fish.enable = true; };

  mcpServers = {
    everything = {
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-everything"
      ];
    };
  };

  mcp = hm {
    dotnix.ai.mcp = {
      enable = true;
      servers = mcpServers;
    };
    dotnix.ai.claude.enable = true;
    dotnix.ai.codex.enable = true;
  };
  mcpFiles = lib.attrNames mcp.home.file;

  piOverride = hm {
    dotnix.ai.pi = {
      enable = true;
      package = pkgs.hello;
    };
  };

  helix = hm { dotnix.editors.helix.enable = true; };
  helixLangs = lib.listToAttrs (
    map (l: lib.nameValuePair l.name l) helix.programs.helix.languages.language
  );

  # --- helix: scls/lsp-ai (word completion + local-llm completion) ---
  # kept in its own block near the existing helix checks above to minimise
  # merge conflicts with other agents appending pi/claude checks.
  helixAi = hm {
    dotnix.editors.helix = {
      enable = true;
      wordCompletion.enable = true;
      ai = {
        enable = true;
        endpoint = "http://127.0.0.1:8000/v1";
        model = "local";
        apiKeyFile = "~/.config/hive/local-key";
      };
    };
  };
  helixAiLangs = lib.listToAttrs (
    map (l: lib.nameValuePair l.name l) helixAi.programs.helix.languages.language
  );
  helixAiServers = helixAi.programs.helix.languages.language-server;
  # whole rendered languages.toml set, serialized, to check no literal key leaks in
  helixAiRendered = builtins.toJSON helixAi.programs.helix.languages;

  helixMissingUpstream = hmUnchecked {
    dotnix.editors.helix = {
      enable = true;
      wordCompletion.enable = true;
      languages.yaml = { };
    };
  };

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

    "claude skills land through programs.claude-code" =
      claude.programs.claude-code.skills.demo == ../config/skills/web-research;
    "claude turns off the raw skills.nix symlink once it owns skills" =
      !claude.dotnix.ai.skills.targets.claude;
    "claude settings stay empty by default, so settings.json is left alone" =
      claude.programs.claude-code.settings == { };
    "claude writes no settings.json when settings stay empty" =
      !(lib.elem "/home/test/.claude/settings.json" claudeFiles);

    "codex skills land through programs.codex" =
      codex.programs.codex.skills.demo == ../config/skills/web-research;
    "codex turns off the raw skills.nix symlink once it owns skills" =
      !codex.dotnix.ai.skills.targets.codex;
    "codex writes its skill once, through programs.codex" = lib.elem ".codex/skills/demo" codexFiles;
    "codex settings stay empty by default, so config.toml is left alone" =
      codex.programs.codex.settings == { };
    "codex writes no config.toml when settings stay empty" =
      !(lib.elem ".codex/config.toml" codexFiles);

    "fish exposes claude bypass" =
      fish.programs.fish.shellAliases.clauded == "claude --dangerously-skip-permissions";
    "fish exposes codex bypass" =
      fish.programs.fish.shellAliases.codexd == "codex --dangerously-bypass-approvals-and-sandbox";
    "fish exposes named claude bypass" =
      fish.programs.fish.shellAliases.claude-yolo == "claude --dangerously-skip-permissions";
    "fish exposes named codex bypass" =
      fish.programs.fish.shellAliases.codex-yolo == "codex --dangerously-bypass-approvals-and-sandbox";
    "fish exposes sandboxed codex" =
      fish.programs.fish.shellAliases.codex-sandbox
      == "codex --sandbox workspace-write --ask-for-approval never";

    "mcp passes servers to programs.mcp" = mcp.programs.mcp.servers.everything.command == "npx";
    "mcp turns on claude integration by default" = mcp.programs.claude-code.enableMcpIntegration;
    "mcp turns on codex integration by default" = mcp.programs.codex.enableMcpIntegration;
    "mcp writes the shared mcp.json" = lib.elem "/home/test/.config/mcp/mcp.json" mcpFiles;

    "pi package override is honored" = piOverride.dotnix.ai.pi.package == pkgs.hello;

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

    # --- helix: scls/lsp-ai ---
    "helix scls server defined" = helixAiServers ? scls;
    "helix lsp-ai server defined" = helixAiServers ? lsp-ai;
    "helix scls appended to language with explicit servers" =
      lib.elem "scls" helixAiLangs.nix.language-servers;
    "helix scls appended to language kept at upstream default" =
      lib.elem "scls" helixAiLangs.rust.language-servers
      && lib.elem "rust-analyzer" helixAiLangs.rust.language-servers;
    "helix lsp-ai appended to default ai.languages" =
      lib.elem "lsp-ai" helixAiLangs.rust.language-servers;
    "helix lsp-ai not appended outside ai.languages" =
      !(lib.elem "lsp-ai" helixAiLangs.markdown.language-servers);
    "helix scls appended everywhere regardless of ai.languages" =
      lib.elem "scls" helixAiLangs.markdown.language-servers;
    "helix lsp-ai model config has endpoint and model" =
      helixAiServers.lsp-ai.config.models.model1.chat_endpoint
      == "http://127.0.0.1:8000/v1/chat/completions"
      && helixAiServers.lsp-ai.config.models.model1.model == "local";
    "helix lsp-ai reads key via env var, not inline" =
      !(helixAiServers.lsp-ai.config.models.model1 ? auth_token);
    "helix rendered languages.toml has no api key field at all" =
      !(lib.hasInfix "auth_token\"" helixAiRendered);
    "helix missing upstream servers trips assertion" = lib.any (lib.hasInfix "languageServers = null") (
      failedAssertions helixMissingUpstream
    );
    "firefox is off by default" = !firefoxOff.programs.firefox.enable;
    "firefox user settings override built-in defaults" =
      firefoxProfile.settings."browser.startup.page" == 1
      && firefoxProfile.settings."privacy.donottrackheader.enabled";
    "firefox profile path adopts an existing directory" = firefoxProfile.path == "abc.default";
    "firefox extension is force-installed by slug" =
      firefoxPolicies.ExtensionSettings."uBlock0@raymondhill.net".install_url
      == "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
    "firefox telemetry off by default" = firefoxPolicies.DisableTelemetry;
    "chatgpt app is installed when enabled" =
      lib.elem chatgpt.dotnix.ai.chatgpt.package chatgpt.home.packages;
    "chatgpt app is absent by default" =
      !(lib.elem chatgptOff.dotnix.ai.chatgpt.package chatgptOff.home.packages);
  };

  firefox = hm {
    dotnix.apps.firefox = {
      enable = true;
      profile.path = "abc.default";
      settings."browser.startup.page" = 1;
      extensions."uBlock0@raymondhill.net" = "ublock-origin";
    };
  };
  firefoxProfile = firefox.programs.firefox.profiles.default;
  firefoxPolicies = firefox.programs.firefox.policies;

  firefoxOff = hm { };

  chatgpt = hm {
    dotnix.ai.chatgpt = {
      enable = true;
      package = pkgs.hello;
    };
  };
  chatgptOff = hm {
    dotnix.ai.chatgpt.package = pkgs.hello;
  };

  failed = lib.attrNames (lib.filterAttrs (_: ok: !ok) checks);
in
assert lib.assertMsg (
  failed == [ ]
) "home-modules checks failed: ${lib.concatStringsSep ", " failed}";
pkgs.runCommand "home-modules-eval" { } "touch $out"
