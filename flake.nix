{
  description = "dotnix: reusable nixos and home-manager modules, plus my hosts";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # daily builds of pi, claude-code and codex; not following nixpkgs keeps
    # their binary cache usable
    llm-agents.url = "github:numtide/llm-agents.nix";
    # own skills, notes and tooling; private, so fetched over ssh
    agents = {
      url = "git+ssh://git@github.com/hz2/agents";
      flake = false;
    };
    # upstream verification skills, pinned for reproducible installation
    cursor-plugins = {
      url = "github:cursor/plugins";
      flake = false;
    };
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.treefmt-nix.flakeModule
        ./parts/checks.nix
        ./parts/dev.nix
        ./parts/hooks.nix
        ./parts/home.nix
        ./parts/modules.nix
        ./parts/nixos.nix
        ./parts/packages.nix
      ];
    };
}
