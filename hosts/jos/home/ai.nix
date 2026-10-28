{ config, pkgs, ... }:
{
  # local llm tooling for the hive lab (~/srcs/hive)
  home.packages = [
    pkgs.python3Packages.huggingface-hub # hf cli
    pkgs.sops
    pkgs.age
  ];

  dotnix.ai = {
    pi = {
      enable = true;
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
  };
}
