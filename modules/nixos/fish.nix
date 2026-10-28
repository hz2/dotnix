{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.system.fish;
in
{
  options.dotnix.system.fish.enable = lib.mkEnableOption ''
    fish, with interactive bash handing off to it so bash stays the posix login shell
  '';

  config = lib.mkIf cfg.enable {
    programs.fish.enable = true;
    programs.bash.interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };
}
