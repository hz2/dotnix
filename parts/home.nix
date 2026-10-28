{ inputs, self, ... }:
{
  # standalone home-manager for non-nixos machines: `home-manager switch --flake .#jos`
  flake.homeConfigurations.jos = inputs.home-manager.lib.homeManagerConfiguration {
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
          name = "jos";
          fullName = "Jason Devers";
          email = "jsondevers@gmail.com";
        };
        home.stateVersion = "24.11";
        dotnix = {
          shell.fish.enable = true;
          shell.cliTools.enable = true;
          git = {
            enable = true;
            userName = "hz2";
            userEmail = "hz2@users.noreply.github.com";
          };
          editors.helix.enable = true;
          ai.pi.enable = true;
          ai.web.enable = true;
        };
      }
    ];
  };
}
