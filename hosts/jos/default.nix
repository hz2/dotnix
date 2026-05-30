{ pkgs, ... }:

{
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
  networking.extraHosts            = "192.168.1.3 lab.local";

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
  security.pam.services.hyprlock                = {};
  security.pam.services.greetd.enableGnomeKeyring = true;

  # --------------------
  # user
  # --------------------
  users.users.jos = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell        = pkgs.fish;
  };

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
  # nix
  # --------------------
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store   = true;
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.11";
}
