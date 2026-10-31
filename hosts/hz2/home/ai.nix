{
  config,
  pkgs,
  inputs,
  ...
}:
let
  # daily llm-agents builds (numtide, not followed to nixpkgs) in place of the
  # slower-moving nixpkgs packages; see modules/home/ai/{pi,claude,codex}.nix
  # for the nixpkgs-only fallback these overrides replace
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  # local llm tooling for the hive lab (~/src/hive)
  home.packages = [
    pkgs.python3Packages.huggingface-hub # hf cli
    pkgs.sops
    pkgs.age
  ];

  dotnix.ai = {
    pi = {
      enable = true;
      package = llmAgents.pi;
      # pi talks to the laptop vllm from hive scripts/devbox-vllm.sh; the key is
      # generated there and read at runtime so it never enters the store
      providers.hive-local = {
        baseUrl = "http://127.0.0.1:8000/v1";
        api = "openai-completions";
        apiKey = "!cat ${config.home.homeDirectory}/.config/hive/local-key";
        models.local = {
          name = "Qwen3 (hive devbox)";
          reasoning = true;
          contextWindow = 16384;
          maxTokens = 4096;
        };
      };
      settings = {
        defaultProvider = "hive-local";
        defaultModel = "local";
      };
      contextFiles."Global Claude instructions" = "~/.claude/CLAUDE.md";
    };
    rtk.enable = true;
    web.enable = true;
    skills = {
      enable = true;
      # claude code has its own web tools on this box
      skills.web-research = null;
    };
    claude = {
      enable = true;
      # claude comes from its native self-updating installer; nix only manages
      # skills, and settings.json stays whatever the cli writes there
      package = null;
    };
    codex.package = llmAgents.codex;
  };
}
