{ inputs, self, ... }:
{
  # standalone home-manager for non-nixos machines: `home-manager switch --flake .#hz2`
  flake.homeConfigurations.hz2 = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      overlays = [ self.overlays.default ];
      config.allowUnfree = true;
    };
    extraSpecialArgs = { inherit inputs self; };
    modules = [
      self.homeModules.default
      {
        dotnix.user = {
          name = "hz2";
          email = "hz2@users.noreply.github.com";
        };
        home.stateVersion = "24.11";
        dotnix = {
          shell.fish.enable = true;
          shell.cliTools.enable = true;
          git.enable = true;
          editors.helix.enable = true;
          ai.pi.enable = true;
          ai.web.enable = true;
        };
      }
    ];
  };
}
