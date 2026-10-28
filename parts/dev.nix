{
  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        programs.shfmt.enable = true;
      };

      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.nil
          pkgs.nixfmt
          pkgs.nvd
          pkgs.nix-diff
          pkgs.nix-tree
        ];
      };
    };
}
