{
  osConfig ? null,
  inputs,
  ...
}:
let
  # home-manager.nixosModules.home-manager passes osConfig; fall back to the
  # plain sops-nix runtime path for a standalone home where it's null.
  secretPath =
    name:
    if osConfig == null then
      "/run/secrets/${name}"
    else
      osConfig.sops.secrets.${name}.path or "/run/secrets/${name}";
in
{
  imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

  programs.openclaw = {
    enable = true;

    runtimePlugins = [ "discord" ];

    environment = {
      DISCORD_BOT_TOKEN = secretPath "discord-bot-token";
      ANTHROPIC_API_KEY = secretPath "anthropic-api-key";
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
