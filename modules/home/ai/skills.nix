{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.ai.skills;

  # skill dirs each agent scans, relative to $HOME
  dirs = {
    claude = ".claude/skills";
    pi = ".pi/agent/skills";
    codex = ".codex/skills";
    opencode = ".config/opencode/skills";
  };

  enabledSkills = lib.filterAttrs (_: v: v != null) cfg.skills;

  # cheap-test names a model, so it is rendered rather than copied
  cheapTest = pkgs.runCommand "skill-cheap-test" { } ''
    mkdir -p $out
    substitute ${../../../config/skills/cheap-test/SKILL.md} $out/SKILL.md \
      --replace-fail @cheapModel@ ${lib.escapeShellArg cfg.cheapModel}
  '';
in
{
  options.dotnix.ai.skills = {
    enable = lib.mkEnableOption "declarative agent skills shared across coding agents";
    skills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.path);
      default = { };
      description = ''
        Skill directories (each holding a SKILL.md) keyed by skill name.
        Set an entry to null to drop a built-in.
      '';
    };
    targets = lib.mapAttrs (
      agent: _:
      lib.mkOption {
        type = lib.types.bool;
        default = agent != "opencode";
        description = "Install skills into ~/${dirs.${agent}}.";
      }
    ) dirs;
    cheapModel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "openai/gpt-5.4-nano";
      description = "Pi model for the cheap-test skill; null leaves the skill out.";
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.ai.skills.skills.cheap-test = lib.mkIf (cfg.cheapModel != null) (lib.mkDefault cheapTest);

    # per-skill links, so the rest of each agent dir stays unmanaged
    home.file = lib.mkMerge (
      lib.mapAttrsToList (
        agent: dir:
        lib.mkIf cfg.targets.${agent} (
          lib.mapAttrs' (
            name: src:
            lib.nameValuePair "${dir}/${name}" {
              source = src;
              recursive = true;
            }
          ) enabledSkills
        )
      ) dirs
    );
  };
}
