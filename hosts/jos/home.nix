{ config, pkgs, ... }:
{
  imports = [
    ./home/ai.nix
    ./home/openclaw.nix
  ];

  home.stateVersion = "24.11";

  dotnix = {
    terminal = {
      alacritty.enable = true;
      tmux.enable = true;
    };
    shell = {
      fish.enable = true;
      ssh.enable = true;
      cliTools.enable = true;
    };
    dev = {
      direnv.enable = true;
      toolchain.enable = true;
    };
    git = {
      enable = true;
      # keep the short handle as author name, not fullName
      userName = "jos";
      editor = "hx";
      sendEmail = {
        # lkml patch submission; password lives in gnome-keyring
        enable = true;
        smtpUser = "hz2@users.noreply.github.com";
        from = "Jason Devers <hz2@users.noreply.github.com>";
      };
    };
    desktop.hyprland.enable = true;
    apps.latex.enable = true;
    editors.helix.enable = true;
    # kept until helix muscle memory sticks
    editors.neovim = {
      enable = true;
      configPath = "${config.home.homeDirectory}/nixos/config/nvim";
    };
  };

  home.packages = [
    pkgs.lazygit
    pkgs.xdg-utils
    pkgs.zoxide
    pkgs.zotero
  ];

  home.sessionVariables = {
    BROWSER = "firefox";
    TERM = "alacritty";
  };

  programs.home-manager.enable = true;
}
