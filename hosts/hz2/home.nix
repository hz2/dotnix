{ config, pkgs, ... }:
{
  imports = [
    ./home/ai.nix
    ./home/openclaw.nix
  ];

  home = {
    stateVersion = "24.11";

    packages = [
      pkgs.lazygit
      pkgs.xdg-utils
      pkgs.zoxide
      pkgs.zotero
    ];

    sessionVariables = {
      BROWSER = "firefox";
      TERM = "alacritty";
    };
  };

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
      editor = "hx";
    };
    desktop.hyprland.enable = true;
    apps.latex.enable = true;
    editors.helix = {
      enable = true;
      wordCompletion.enable = true;
      ai = {
        enable = true;
        endpoint = "http://127.0.0.1:8000/v1";
        model = "local";
        apiKeyFile = "~/.config/hive/local-key";
      };
    };
    # kept until helix muscle memory sticks
    editors.neovim = {
      enable = true;
      configPath = "${config.home.homeDirectory}/src/dotnix/config/nvim";
    };
  };

  programs.home-manager.enable = true;
}
