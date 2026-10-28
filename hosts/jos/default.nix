{
  config,
  pkgs,
  inputs,
  ...
}:
let
  user = config.dotnix.user;
in
{
  imports = [ ./hardware.nix ];

  home-manager.users.${user.name} = import ./home.nix;

  nixpkgs.overlays = [ inputs.nix-openclaw.overlays.default ];

  dotnix = {
    user = {
      name = "jos";
      fullName = "Jason Devers";
      email = "jsondevers@gmail.com";
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
      };
      fish.enable = true;
      fonts.enable = true;
      audio.enable = true;

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

  # no sshd on this host, so there's no /etc/ssh host key for agenix to use
  # by default; decrypt with the personal key instead
  age.identityPaths = [ "${user.homeDirectory}/.ssh/id_ed25519" ];
  age.secrets = {
    discord-bot-token = {
      file = ../../secrets/discord-bot-token.age;
      owner = user.name;
    };
    anthropic-api-key = {
      file = ../../secrets/anthropic-api-key.age;
      owner = user.name;
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "i915.enable_psr=0" ];

  networking.hostName = "jos";
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
