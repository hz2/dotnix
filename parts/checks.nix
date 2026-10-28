{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        home-modules = import ../tests/home-modules.nix { inherit pkgs self inputs; };
        # nix flake check doesn't build nixosConfigurations on its own
        hz2 = self.nixosConfigurations.hz2.config.system.build.toplevel;
        home-hz2 = self.homeConfigurations.hz2.activationPackage;
      };
    };
}
