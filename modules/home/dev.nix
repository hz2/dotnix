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
    home.packages = [
      pkgs.rustup
      pkgs.gcc
      pkgs.cmake
      pkgs.gnumake
      pkgs.pkg-config

      # LSPs (rust-analyzer comes from rustup, declared per-project in rust-toolchain.toml)
      pkgs.lua-language-server
      pkgs.nil
      pkgs.clang-tools

      # Dev tools
      pkgs.gh
      pkgs.htop
      pkgs.nixfmt
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
