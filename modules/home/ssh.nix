{ config, lib, ... }:
let
  cfg = config.dotnix.shell.ssh;
in
{
  options.dotnix.shell.ssh.enable = lib.mkEnableOption "ssh agent and connection multiplexing";

  config = lib.mkIf cfg.enable {
    services.ssh-agent.enable = true;

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings = {
        "*" = {
          AddKeysToAgent = "yes";
          ControlMaster = "auto";
          ControlPath = "~/.ssh/sockets/%r@%h-%p";
          ControlPersist = "10m";
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
          HashKnownHosts = true;
        };
        "github.com" = {
          Hostname = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/id_ed25519";
        };
      };
    };
  };
}
