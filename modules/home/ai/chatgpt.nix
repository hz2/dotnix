{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.ai.chatgpt;
in
{
  options.dotnix.ai.chatgpt = {
    enable = lib.mkEnableOption "the ChatGPT and Codex desktop app, used for remote sessions";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.chatgpt;
      defaultText = lib.literalExpression "pkgs.chatgpt";
      description = "Desktop app package. The llm-agents flake ships a newer build than nixpkgs.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
