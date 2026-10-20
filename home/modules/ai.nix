{ pkgs, ... }:

{
  # local llm tooling for the hive lab (~/srcs/hive)
  home.packages = with pkgs; [
    python3Packages.huggingface-hub # hf cli
    sops
    age
  ];
}
