{ pkgs, lib, inputs, ... }:

{
  # --------------------
  # nix overlays
  # --------------------
  nixpkgs.overlays = [ inputs.nix-openclaw.overlays.default ];

  # --------------------
  # secrets (agenix)
  # --------------------
  # no sshd on this host, so there's no /etc/ssh host key for agenix to use
  # by default - decrypt with the personal key instead
  age.identityPaths = [ "/home/jos/.ssh/id_ed25519" ];
  age.secrets = {
    discord-bot-token = {
      file  = ../../secrets/discord-bot-token.age;
      owner = "jos";
    };
    anthropic-api-key = {
      file  = ../../secrets/anthropic-api-key.age;
      owner = "jos";
    };
  };

  # --------------------
  # boot
  # --------------------
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams                    = [ "i915.enable_psr=0" ];

  # --------------------
  # networking
  # --------------------
  networking.hostName              = "jos";
  networking.networkmanager.enable = true;
  networking.extraHosts            = "192.168.1.20 nipogi";

  # --------------------
  # locale / time
  # --------------------
  time.timeZone      = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # --------------------
  # keyboard
  # --------------------
  services.xserver.xkb = {
    layout  = "us";
    options = "caps:escape";
  };

  # --------------------
  # Hyprland
  # --------------------
  programs.hyprland = {
    enable          = true;
    xwayland.enable = true;
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
      user    = "greeter";
    };
  };

  # --------------------
  # audio
  # --------------------
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
    wireplumber.enable = true;
  };

  # --------------------
  # hardware
  # --------------------
  hardware.graphics.enable = true;
  hardware.bluetooth = {
    enable       = true;
    powerOnBoot  = true;
  };

  # --------------------
  # portals
  # --------------------
  xdg.portal = {
    enable       = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  # --------------------
  # security
  # --------------------
  security.polkit.enable                         = true;
  security.sudo.wheelNeedsPassword               = false;
  security.pam.services.hyprlock                = {};
  security.pam.services.greetd.enableGnomeKeyring = true;

  # --------------------
  # user
  # --------------------
  users.users.jos = {
    isNormalUser = true;
    # dialout: serial access to /dev/ttyACM* (e.g. Flipper Zero) without a
    # manual chmod every time it reconnects - see the udev rule below
    extraGroups  = [ "wheel" "networkmanager" "video" "audio" "input" "docker" "dialout" ];
    shell        = pkgs.fish;
  };

  # --------------------
  # flipper zero (subghz dev)
  # --------------------
  # by default /dev/ttyACM* is root:dialout mode 0660, which only helps once
  # the user is actually in the dialout group above; this udev rule scopes
  # that to the Flipper's USB CDC ACM interface specifically (vendor/product
  # id 0483:5740, ST's default VID + Flipper's PID) so other serial devices
  # aren't affected. needed for `fbt launch` / flashing over USB.
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", MODE="0660", GROUP="dialout"
  '';

  # --------------------
  # shell
  # --------------------
  programs.fish.enable = true;
  programs.bash.interactiveShellInit = ''
    if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
    then
      shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
      exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
    fi
  '';

  # --------------------
  # system packages
  # --------------------
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    gcc
    wl-clipboard
    wlr-randr
    ripgrep
    fd
    fzf
    jq
    tree
    btop
    docker
    firefox
    brightnessctl
    playerctl
    blueman
    networkmanagerapplet
    pavucontrol
  ];

  programs.nix-ld.enable = true;

  # --------------------
  # virtualisation
  # --------------------
  virtualisation.docker.enable = true;

  # --------------------
  # fonts
  # --------------------
  fonts = {
    fontconfig.enable = true;
    packages = with pkgs; [
      nerd-fonts.hack
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
      font-awesome
    ];
  };

  # --------------------
  # memory pressure
  # --------------------
  # 16 GB shared by the local vllm server (~8 GB, ~/srcs/hive scripts/devbox-vllm.sh)
  # and nix builds; on 2026-10-26 a nix-daemon vm test build pushed the box into a
  # global oom and the kernel killed vllm (see ~/srcs/hive docs/hardware.md).
  # zram gives spikes somewhere to go, and builds are fenced in their own cgroup
  # so a runaway build dies instead of the server.
  zramSwap = {
    enable        = true;
    memoryPercent = 50;
  };
  # zram has no seek cost, so swap in single pages instead of read-ahead clusters
  boot.kernel.sysctl."vm.page-cluster" = 0;
  # vllm itself never swaps: devbox-vllm.sh runs it with --memory = --memory-swap (10g)

  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh     = "5G";   # throttle builds first
    MemoryMax      = "6G";   # then oom-kill inside the build cgroup only
    OOMScoreAdjust = 500;    # under global pressure, builds go before vllm
  };

  # --------------------
  # nix
  # --------------------
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store   = true;
    # was max-jobs = 12 with cores = 0: twelve parallel builds each using every core
    max-jobs = 2;
    cores    = 6;
  };

  nixpkgs.config.allowUnfree = true;
  # zotero still bundles esr 140 as its runtime, drop once nixpkgs bumps it
  nixpkgs.config.permittedInsecurePackages = [ "firefox-esr-140-bin-unwrapped-140.17.0esr" ];

  system.stateVersion = "24.11";
}
