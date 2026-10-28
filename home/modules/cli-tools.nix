{ pkgs, ... }:

{
  home.packages = with pkgs; [ lazygit ];

  programs.bat = {
    enable = true;
    config = {
      theme = "base16";
      style = "changes,header";
    };
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    git = true;
    icons = "auto";
  };
}
