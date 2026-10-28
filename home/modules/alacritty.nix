{ ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 10;
          y = 10;
        };
        decorations = "None";
        opacity = 0.85;
      };

      font = {
        normal = {
          family = "Hack Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "Hack Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "Hack Nerd Font";
          style = "Italic";
        };
        size = 12.0;
      };

      cursor.style = {
        shape = "Block";
        blinking = "Off";
      };

      # Nightfox — nordfox palette
      colors = {
        primary = {
          background = "#2e3440";
          foreground = "#cdcecf";
          dim_foreground = "#abb1bb";
          bright_foreground = "#c7cdd9";
        };
        cursor = {
          text = "#cdcecf";
          cursor = "#abb1bb";
        };
        vi_mode_cursor = {
          text = "#cdcecf";
          cursor = "#88c0d0";
        };
        search = {
          matches = {
            foreground = "#cdcecf";
            background = "#4f6074";
          };
          focused_match = {
            foreground = "#cdcecf";
            background = "#a3be8c";
          };
        };
        selection = {
          text = "#3b4252";
          background = "#cdcecf";
        };
        normal = {
          black = "#3b4252";
          red = "#bf616a";
          green = "#a3be8c";
          yellow = "#ebcb8b";
          blue = "#81a1c1";
          magenta = "#b48ead";
          cyan = "#88c0d0";
          white = "#e5e9f0";
        };
        bright = {
          black = "#465780";
          red = "#d06179";
          green = "#b1c89d";
          yellow = "#f0d399";
          blue = "#8cafd2";
          magenta = "#c895bf";
          cyan = "#93ccdc";
          white = "#e7ecf4";
        };
        dim = {
          black = "#353a45";
          red = "#a54e56";
          green = "#9aa872";
          yellow = "#d9b263";
          blue = "#668aab";
          magenta = "#9d6795";
          cyan = "#69a7ba";
          white = "#bbc3d4";
        };
      };

      keyboard.bindings = [
        {
          key = "Return";
          mods = "Control|Shift";
          action = "SpawnNewInstance";
        }
      ];
    };
  };
}
