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
}
