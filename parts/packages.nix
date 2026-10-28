{ inputs, self, ... }:
{
  flake.overlays.default = import ../pkgs;

  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    {
      _module.args.pkgs = pkgs;
      packages = {
        inherit (pkgs) dotnix-web rtk;
      };
    };
}
