{ pkgs, config, ... }:

{
  imports = [
    ./modules/alacritty.nix
    ./modules/tmux.nix
    ./modules/fish.nix
    ./modules/git.nix
    ./modules/direnv.nix
    ./modules/ssh.nix
    ./modules/dev.nix
    ./modules/hyprland.nix
    ./modules/cli-tools.nix
    ./modules/latex.nix
  ];

  home.username    = "jos";
  home.homeDirectory = "/home/jos";
  home.stateVersion  = "24.11";

  home.packages = with pkgs; [
    neovim
    lazygit
    xdg-utils
    zoxide
    zotero
  ];

  home.sessionVariables = {
    EDITOR  = "nvim";
    BROWSER = "firefox";
    TERM    = "alacritty";
  };

  programs.home-manager.enable = true;

  # symlink ~/.config entries directly to ~/nixos/config/ (out-of-store so
  # tools like lazy.nvim can still write files like lazy-lock.json)
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/nvim";
}
