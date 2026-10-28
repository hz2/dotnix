{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  cfg = config.dotnix.ai.codex;
  tomlFormat = pkgs.formats.toml { };

  skillsModuleLoaded = options ? dotnix.ai.skills;
in
{
  options.dotnix.ai.codex = {
    enable = lib.mkEnableOption "Codex via home-manager's programs.codex";
    package = lib.mkPackageOption pkgs "codex" { nullable = true; };

    skills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.path);
      default = { };
      description = ''
        Skills merged into programs.codex.skills. Defaults to
        dotnix.ai.skills.skills when dotnix.ai.skills is loaded, which also
        turns off that module's own raw ~/.codex/skills symlinks. Null
        entries are dropped.
      '';
    };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Extra programs.codex.settings. Empty by default so CODEX_HOME's
        config.toml is never touched; the user keeps full control of it.
      '';
    };

    mutableSettings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether a non-empty dotnix.ai.codex.settings merges into the
        existing config.toml instead of replacing it. Irrelevant while
        settings stays empty, which is the default.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.codex = {
          enable = true;
          package = cfg.package;
          settings = cfg.settings;
          mutableSettings = cfg.mutableSettings;
          skills = lib.filterAttrs (_: v: v != null) cfg.skills;
        };
      }
      (lib.optionalAttrs skillsModuleLoaded {
        dotnix.ai.codex.skills = lib.mkDefault config.dotnix.ai.skills.skills;
        # avoid writing the same skills/<name> path twice: once as a raw
        # home.file symlink here, once through programs.codex.skills above
        dotnix.ai.skills.targets.codex = lib.mkDefault false;
      })
    ]
  );
}
