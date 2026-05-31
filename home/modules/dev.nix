{ pkgs, ... }:

{
  home.packages = with pkgs; [
    rustup
    gcc
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
    CARGO_HOME  = "$HOME/.cargo";
  };
}
