{ inputs, self, ... }:
let
  mkHost =
    name:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs self; };
      modules = [
        inputs.determinate.nixosModules.default
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        self.nixosModules.default
        { nixpkgs.overlays = [ self.overlays.default ]; }
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs self; };
          home-manager.backupFileExtension = "bak";
          home-manager.sharedModules = [
            inputs.sops-nix.homeManagerModules.sops
            self.homeModules.default
          ];
        }
        ../hosts/${name}/default.nix
      ];
    };
in
{
  flake.nixosConfigurations.hz2 = mkHost "hz2";
}
