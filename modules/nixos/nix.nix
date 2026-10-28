{ config, lib, ... }:
let
  cfg = config.dotnix.system.nix;
in
{
  options.dotnix.system.nix = {
    enable = lib.mkEnableOption "flakes, store optimisation and unfree packages";
    maxJobs = lib.mkOption {
      type = lib.types.either lib.types.ints.unsigned (lib.types.enum [ "auto" ]);
      default = "auto";
      description = "Parallel builds. Each build may use `cores` cores.";
    };
    cores = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 0;
      description = "Cores per build; 0 means all.";
    };
  };

  config = lib.mkIf cfg.enable {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      max-jobs = cfg.maxJobs;
      inherit (cfg) cores;
    };
    nixpkgs.config.allowUnfree = true;
  };
}
