{ pkgs, config, ... }:

{
  # local llm tooling for the hive lab (~/srcs/hive)
  home.packages = with pkgs; [
    python3Packages.huggingface-hub # hf cli
    sops
    age
    pi-coding-agent
  ];

  # pi talks to the laptop vllm from ~/srcs/hive/scripts/devbox-vllm.sh
  # (key is generated there, read at runtime so it never enters the store)
  home.file.".pi/agent/models.json".text = builtins.toJSON {
    providers.hive-local = {
      baseUrl = "http://127.0.0.1:8000/v1";
      api = "openai-completions";
      apiKey = "!cat ${config.home.homeDirectory}/.config/hive/local-key";
      models = [
        {
          id = "local";
          name = "Qwen3 (hive devbox)";
          reasoning = true;
          input = [ "text" ];
          contextWindow = 16384;
          maxTokens = 4096;
          cost = {
            input = 0;
            output = 0;
            cacheRead = 0;
            cacheWrite = 0;
          };
        }
      ];
    };
  };
}
