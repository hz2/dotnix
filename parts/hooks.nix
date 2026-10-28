{ inputs, ... }:
{
  imports = [ inputs.git-hooks.flakeModule ];

  perSystem = {
    pre-commit.settings.hooks = {
      # git-hooks wires this to config.treefmt.build.wrapper automatically
      # when the treefmt option exists, reusing parts/dev.nix's treefmt-nix config
      treefmt.enable = true;
      gitleaks.enable = true;
    };
  };
}
