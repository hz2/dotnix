{
  description = "jos NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, home-manager, determinate, agenix, nix-openclaw, ... }@inputs: {
    nixosConfigurations.jos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        determinate.nixosModules.default
        agenix.nixosModules.default
        ./hosts/jos/default.nix
        ./hosts/jos/hardware.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs        = true;
          home-manager.useUserPackages      = true;
          home-manager.extraSpecialArgs     = { inherit inputs; };
          home-manager.backupFileExtension  = "bak";
          home-manager.users.jos            = import ./home/jos.nix;
        }
      ];
    };
  };
}
