{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  user = config.dotnix.user;
  secretsFile = ../../secrets/hz2.yaml;
  hasSecrets = builtins.pathExists secretsFile;
in
{
  imports = [ ./hardware.nix ];

  home-manager.users.${user.name} = import ./home.nix;

  nixpkgs.overlays = [ inputs.nix-openclaw.overlays.default ];

  dotnix = {
    user = {
      name = "hz2";
      email = "hz2@users.noreply.github.com";
      # without this, a renamed/recreated user has no password at all (locked,
      # not blank) and no rollback brings one back: generations don't version
      # /etc/shadow. neededForUsers makes sops decrypt it before users activate.
      hashedPasswordFile = lib.mkIf hasSecrets config.sops.secrets.hz2-hashed-password.path;
      # dialout: serial access to /dev/ttyACM* (flipper zero) without a manual
      # chmod every reconnect, see the udev rule below
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
        "input"
        "docker"
        "dialout"
      ];
    };

    system = {
      nix = {
        enable = true;
        # was max-jobs = 12 with cores = 0: twelve parallel builds each using every core
        maxJobs = 2;
        cores = 6;
        numtideCache = true;
      };
      fish.enable = true;
      fonts.enable = true;
      audio.enable = true;
      nh = {
        enable = true;
        clean.enable = true;
      };

      # 16 GB shared by the local vllm server (~8 GB, hive scripts/devbox-vllm.sh)
      # and nix builds; on 2026-10-26 a nix-daemon vm test build pushed the box into
      # a global oom and the kernel killed vllm (hive docs/hardware.md). zram gives
      # spikes somewhere to go, and builds are fenced so a runaway build dies instead.
      # vllm itself never swaps: devbox-vllm.sh runs it with --memory = --memory-swap.
      zram.enable = true;
      nixDaemonFence = {
        enable = true;
        memoryHigh = "5G";
        memoryMax = "6G";
      };
    };

    desktop.hyprland.enable = true;
  };

  # no sshd on this host, so there's no /etc/ssh host key for sops to use
  # by default; decrypt with the personal key instead. secrets/hz2.yaml is
  # created separately, see secrets/README.md; evaluation must not fail
  # before it exists.
  sops.age.sshKeyPaths = [ "${user.homeDirectory}/.ssh/id_ed25519" ];
  sops.defaultSopsFile = secretsFile;
  sops.secrets = lib.mkIf hasSecrets {
    discord-bot-token.owner = user.name;
    anthropic-api-key.owner = user.name;
    # neededForUsers secrets must be root-owned and decrypt before users
    # activate, see modules/common/user.nix
    hz2-hashed-password.neededForUsers = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "i915.enable_psr=0" ];

  networking.hostName = "hz2";
  networking.networkmanager.enable = true;
  networking.extraHosts = "192.168.1.20 nipogi";

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  security.sudo.wheelNeedsPassword = false;

  # flipper zero (subghz dev): scope dialout access to its usb cdc acm interface
  # (st vid 0483, flipper pid 5740) so other serial devices aren't affected.
  # needed for `fbt launch` and flashing over usb.
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", MODE="0660", GROUP="dialout"
  '';

  environment.systemPackages = [
    pkgs.git
    pkgs.wget
    pkgs.curl
    pkgs.gcc
    pkgs.wl-clipboard
    pkgs.wlr-randr
    pkgs.ripgrep
    pkgs.fd
    pkgs.fzf
    pkgs.jq
    pkgs.tree
    pkgs.btop
    pkgs.docker
    pkgs.firefox
    pkgs.brightnessctl
    pkgs.playerctl
    pkgs.blueman
    pkgs.networkmanagerapplet
    pkgs.pavucontrol
  ];

  programs.nix-ld.enable = true;
  virtualisation.docker.enable = true;

  # zotero still bundles esr 140 as its runtime, drop once nixpkgs bumps it
  nixpkgs.config.permittedInsecurePackages = [ "firefox-esr-140-bin-unwrapped-140.17.0esr" ];

  system.stateVersion = "24.11";
}
