{ inputs, ... }:
{
  flake.nixosConfigurations.jos = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      inputs.determinate.nixosModules.default
      inputs.agenix.nixosModules.default
      ../hosts/jos/default.nix
      ../hosts/jos/hardware.nix
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.backupFileExtension = "bak";
        home-manager.users.jos = import ../home/jos.nix;
      }
    ];
  };
}
