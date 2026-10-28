{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.dotnix.user;
in
{
  imports = [ ../common/user.nix ];

  config = lib.mkIf (cfg.name != null) (
    lib.mkMerge [
      {
        users.users.${cfg.name} = {
          isNormalUser = true;
          home = cfg.homeDirectory;
          inherit (cfg) shell extraGroups;
        };
      }
      # optionalAttrs, not mkIf: a mkIf still records the option path and fails
      # when the home-manager nixos module isn't imported
      (lib.optionalAttrs (options ? home-manager) {
        home-manager.sharedModules = [ { dotnix.user = lib.mapAttrs (_: lib.mkDefault) cfg; } ];
      })
    ]
  );
}
