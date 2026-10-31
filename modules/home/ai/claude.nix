{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  cfg = config.dotnix.ai.claude;
  jsonFormat = pkgs.formats.json { };

  # true whenever modules/home/ai/skills.nix is part of this module set; guards
  # cross-module reads/writes so homeModules.claude keeps working standalone
  skillsModuleLoaded = options ? dotnix.ai.skills;
in
{
  options.dotnix.ai.claude = {
    enable = lib.mkEnableOption "Claude Code via home-manager's programs.claude-code";
    package = lib.mkPackageOption pkgs "claude-code" { nullable = true; };

    skills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.path);
      default = { };
      description = ''
        Skills merged into programs.claude-code.skills. Defaults to
        dotnix.ai.skills.skills when dotnix.ai.skills is loaded, which also
        turns off that module's own raw ~/.claude/skills symlinks so the two
        don't both claim the same path. Null entries are dropped.
      '';
    };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Extra programs.claude-code.settings. Empty by default so
        ~/.claude/settings.json is never touched; the user keeps full control
        of it, including CLAUDE.md, hooks and permissions configured through
        the CLI itself.
      '';
    };

    mutableSettings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether a non-empty dotnix.ai.claude.settings merges into the
        existing settings.json instead of replacing it. Irrelevant while
        settings stays empty, which is the default.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.claude-code = {
          enable = true;
          inherit (cfg) package settings mutableSettings;
          skills = lib.filterAttrs (_: v: v != null) cfg.skills;
        };
      }
      (lib.optionalAttrs skillsModuleLoaded {
        dotnix.ai.claude.skills = lib.mkDefault config.dotnix.ai.skills.skills;
        # avoid writing the same skills/<name> path twice: once as a raw
        # home.file symlink here, once through programs.claude-code.skills above
        dotnix.ai.skills.targets.claude = lib.mkDefault false;
      })
    ]
  );
}
