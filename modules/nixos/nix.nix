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
    numtideCache = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Add numtide's binary cache as a substituter, so inputs built by
        numtide (e.g. llm-agents.nix) are fetched instead of built locally.
      '';
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
    }
    // lib.optionalAttrs cfg.numtideCache {
      extra-substituters = [ "https://cache.numtide.com" ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
    nixpkgs.config.allowUnfree = true;
  };
}
