{
  perSystem =
    { config, pkgs, ... }:
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
          pkgs.sops
          pkgs.ssh-to-age
          config.pre-commit.settings.package
        ]
        ++ config.pre-commit.settings.enabledPackages;
        shellHook = config.pre-commit.installationScript;
      };
    };
}
