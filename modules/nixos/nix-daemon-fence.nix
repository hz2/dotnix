{ config, lib, ... }:
let
  cfg = config.dotnix.system.nixDaemonFence;
in
{
  options.dotnix.system.nixDaemonFence = {
    enable = lib.mkEnableOption "a memory cgroup fence around nix builds";
    memoryHigh = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "5G";
      description = "Soft limit; builds get throttled past this.";
    };
    memoryMax = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "6G";
      description = "Hard limit; the oom killer fires inside the build cgroup only.";
    };
    oomScoreAdjust = lib.mkOption {
      type = lib.types.ints.between (-1000) 1000;
      default = 500;
      description = "Under global pressure, builds die before other services.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.nix-daemon.serviceConfig = {
      OOMScoreAdjust = cfg.oomScoreAdjust;
    }
    // lib.optionalAttrs (cfg.memoryHigh != null) { MemoryHigh = cfg.memoryHigh; }
    // lib.optionalAttrs (cfg.memoryMax != null) { MemoryMax = cfg.memoryMax; };
  };
}
