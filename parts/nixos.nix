{ inputs, self, ... }:
let
  mkHost =
    name:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs self; };
      modules = [
        inputs.determinate.nixosModules.default
        inputs.agenix.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        self.nixosModules.default
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs self; };
          home-manager.backupFileExtension = "bak";
        }
        ../hosts/${name}/default.nix
      ];
    };
in
{
  flake.nixosConfigurations.jos = mkHost "jos";
}
