{ config, lib, ... }:
let
  cfg = config.dotnix.system.zram;
in
{
  options.dotnix.system.zram = {
    enable = lib.mkEnableOption "compressed swap in ram";
    memoryPercent = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 50;
      description = "Share of ram the zram device may use.";
    };
  };

  config = lib.mkIf cfg.enable {
    zramSwap = {
      enable = true;
      inherit (cfg) memoryPercent;
    };
    # zram has no seek cost, so swap in single pages instead of read-ahead clusters
    boot.kernel.sysctl."vm.page-cluster" = lib.mkDefault 0;
  };
}
