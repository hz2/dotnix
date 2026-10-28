{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        home-modules = import ../tests/home-modules.nix { inherit pkgs self inputs; };
        # nix flake check doesn't build nixosConfigurations on its own
        jos = self.nixosConfigurations.jos.config.system.build.toplevel;
        home-jos = self.homeConfigurations.jos.activationPackage;
      };
    };
}
