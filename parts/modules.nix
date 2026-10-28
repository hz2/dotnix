{
  flake.nixosModules = {
    default = ../modules/nixos;
    audio = ../modules/nixos/audio.nix;
    fish = ../modules/nixos/fish.nix;
    fonts = ../modules/nixos/fonts.nix;
    hyprland = ../modules/nixos/hyprland.nix;
    nix = ../modules/nixos/nix.nix;
    nix-daemon-fence = ../modules/nixos/nix-daemon-fence.nix;
    user = ../modules/nixos/user.nix;
    zram = ../modules/nixos/zram.nix;
  };

  flake.homeModules = {
    default = ../modules/home;
    alacritty = ../modules/home/alacritty.nix;
    cli-tools = ../modules/home/cli-tools.nix;
    dev = ../modules/home/dev.nix;
    direnv = ../modules/home/direnv.nix;
    fish = ../modules/home/fish.nix;
    git = ../modules/home/git.nix;
    hyprland = ../modules/home/hyprland.nix;
    latex = ../modules/home/latex.nix;
    neovim = ../modules/home/editors/neovim.nix;
    ssh = ../modules/home/ssh.nix;
    tmux = ../modules/home/tmux.nix;
    user = ../modules/home/user.nix;
  };
}
