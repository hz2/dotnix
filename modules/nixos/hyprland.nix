{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.desktop.hyprland;
in
{
  options.dotnix.desktop.hyprland = {
    enable = lib.mkEnableOption "hyprland with greetd, portals and polkit";
    xkb = {
      layout = lib.mkOption {
        type = lib.types.str;
        default = "us";
        description = "Keyboard layout.";
      };
      options = lib.mkOption {
        type = lib.types.str;
        default = "caps:escape";
        description = "Keyboard options.";
      };
    };
    greeter = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
      defaultText = lib.literalExpression ''"''${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland"'';
      description = "greetd default session command.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.xkb = {
      inherit (cfg.xkb) layout options;
    };

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    services.greetd = {
      enable = true;
      settings.default_session = {
        command = cfg.greeter;
        user = "greeter";
      };
    };

    hardware.graphics.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    security.polkit.enable = true;
    security.pam.services.hyprlock = { };
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
