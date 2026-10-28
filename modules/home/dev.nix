{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.dev.toolchain;
in
{
  options.dotnix.dev.toolchain.enable = lib.mkEnableOption "rustup, c toolchain, go and nix tooling";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      rustup
      gcc
      cmake
      gnumake
      pkg-config

      # LSPs (rust-analyzer comes from rustup, declared per-project in rust-toolchain.toml)
      lua-language-server
      nil
      clang-tools

      # Dev tools
      gh
      htop
      nixfmt
    ];

    programs.go = {
      enable = true;
      env.GOPATH = "~/go";
    };

    home.sessionVariables = {
      RUSTUP_HOME = "$HOME/.rustup";
      CARGO_HOME = "$HOME/.cargo";
    };
  };
}
