{ inputs, ... }:

{
  imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

  programs.openclaw = {
    enable = true;

    runtimePlugins = [ "discord" ];

    environment = {
      DISCORD_BOT_TOKEN = "/run/agenix/discord-bot-token";
      ANTHROPIC_API_KEY = "/run/agenix/anthropic-api-key";
    };

    config = {
      gateway.mode = "local";

      channels.discord = {
        enabled = true;
        token = {
          source = "env";
          provider = "default";
          id = "DISCORD_BOT_TOKEN";
        };
      };

      models.providers.anthropic.apiKey = {
        source = "env";
        provider = "default";
        id = "ANTHROPIC_API_KEY";
      };
    };
  };
}
