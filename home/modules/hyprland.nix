{ pkgs, ... }:

{
  home.packages = with pkgs; [
    hyprlock
    hyprpaper
    grim
    slurp
    swappy
    wl-clipboard
    brightnessctl
    playerctl
    blueman
    networkmanagerapplet
    pavucontrol
  ];

  wayland.windowManager.hyprland = {
    enable     = true;
    configType = "hyprlang";

    settings = {
      monitor = ",preferred,auto,1";

      exec-once = [
        "waybar"
        "mako"
        "hyprpaper"
        "hypridle"
        "nm-applet --indicator"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Adwaita"
        "QT_QPA_PLATFORM,wayland"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "GDK_BACKEND,wayland,x11"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
      ];

      general = {
        gaps_in   = 5;
        gaps_out  = 10;
        border_size = 2;
        "col.active_border"   = "rgba(81a1c1ee) rgba(b48eadee) 45deg";
        "col.inactive_border" = "rgba(3b4252aa)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
        blur     = { enabled = true; size = 6; passes = 3; };
        shadow   = { enabled = true; range = 8; color = "rgba(1a1a2eee)"; };
      };

      animations = {
        enabled = true;
        bezier  = [ "smooth, 0.05, 0.9, 0.1, 1.05" ];
        animation = [
          "windows,    1, 6, smooth"
          "windowsOut, 1, 6, default, popin 80%"
          "border,     1, 8, default"
          "fade,       1, 6, default"
          "workspaces, 1, 5, default"
        ];
      };

      dwindle = { preserve_split = true; };

      input = {
        kb_layout  = "us";
        kb_options = "caps:escape";
        follow_mouse = 1;
        sensitivity  = 0;
        touchpad = { natural_scroll = true; disable_while_typing = true; };
      };

      misc = { force_default_wallpaper = 0; disable_hyprland_logo = true; };

      "$mod" = "SUPER";

      bind = [
        "$mod, Return,   exec, alacritty"
        "$mod, R,        exec, rofi -show drun"
        "$mod, E,        exec, thunar"
        "$mod, Q,        killactive"
        "$mod, V,        togglefloating"
        "$mod, F,        fullscreen"
        "$mod SHIFT, M,  exit"

        "$mod, h, movefocus, l"
        # "$mod, l, movefocus, r"  # l freed up for lock below
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"

        "$mod SHIFT, h, movewindow, l"
        # "$mod SHIFT, l, movewindow, r"  # l freed up for lock below
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, j, movewindow, d"

        "$mod, L, exec, hyprlock"

        "$mod, 1, workspace, 1"   "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod, 2, workspace, 2"   "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod, 3, workspace, 3"   "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod, 4, workspace, 4"   "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod, 5, workspace, 5"   "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod, 6, workspace, 6"   "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod, 7, workspace, 7"   "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod, 8, workspace, 8"   "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod, 9, workspace, 9"   "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod, 0, workspace, 10"  "$mod SHIFT, 0, movetoworkspace, 10"

        ",     Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        "$mod, Print, exec, grim - | wl-copy"

        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up,   workspace, e-1"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindel = [
        ", XF86AudioRaiseVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute,         exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86MonBrightnessUp,   exec, brightnessctl set 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
      ];

      bindl = [
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioNext, exec, playerctl next"
      ];

      windowrule = [
        "suppress_event maximize, match:class .*"
        "no_focus on, match:class ^$, match:title ^$, match:xwayland 1, match:float 1, match:fullscreen 0, match:pin 0"
      ];
    };
  };

  # ---------- Waybar ----------
  programs.waybar = {
    enable = true;
    settings = [{
      layer    = "top";
      position = "top";
      height   = 30;
      spacing  = 4;

      modules-left   = [ "hyprland/workspaces" ];
      modules-center = [ "hyprland/window" ];
      modules-right  = [ "pulseaudio" "network" "battery" "clock" "tray" ];

      "hyprland/workspaces" = {
        disable-scroll = true;
        all-outputs    = true;
        format         = "{icon}";
        format-icons   = {
          "1" = ""; "2" = ""; "3" = ""; "4" = ""; "5" = "";
          urgent  = "";
          focused = "";
          default = "";
        };
      };

      clock = {
        format     = " {:%H:%M}";
        format-alt = " {:%Y-%m-%d}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      };

      battery = {
        states          = { warning = 30; critical = 15; };
        format          = "{icon} {capacity}%";
        format-charging = " {capacity}%";
        format-plugged  = " {capacity}%";
        format-icons    = [ "" "" "" "" "" ];
      };

      network = {
        format-wifi         = " {essid}";
        format-ethernet     = " {ipaddr}";
        format-disconnected = "⚠ No network";
        tooltip-format-wifi = "{signalStrength}% signal";
      };

      pulseaudio = {
        format       = "{icon} {volume}%";
        format-muted = " muted";
        format-icons = { headphone = ""; default = [ "" "" " " ]; };
        on-click     = "pavucontrol";
      };

      tray.spacing = 10;
    }];

    style = ''
      * {
        font-family: "Hack Nerd Font";
        font-size: 13px;
        border: none;
        border-radius: 0;
        min-height: 0;
      }
      window#waybar {
        background: rgba(46, 52, 64, 0.9);
        color: #cdcecf;
        border-bottom: 2px solid rgba(129, 161, 193, 0.4);
      }
      #workspaces button {
        padding: 0 8px;
        background: transparent;
        color: #4c566a;
        border-bottom: 2px solid transparent;
      }
      #workspaces button.active,
      #workspaces button.focused {
        color: #81a1c1;
        border-bottom: 2px solid #81a1c1;
      }
      #workspaces button.urgent {
        color: #bf616a;
        border-bottom: 2px solid #bf616a;
      }
      #clock, #battery, #network, #pulseaudio, #tray {
        padding: 0 12px;
        color: #cdcecf;
      }
      #battery.warning  { color: #ebcb8b; }
      #battery.critical { color: #bf616a; }
      #window           { color: #88c0d0; }
    '';
  };

  # ---------- Mako ----------
  services.mako = {
    enable = true;
    settings = {
      background-color = "#2e3440";
      border-color     = "#81a1c1";
      text-color       = "#cdcecf";
      border-radius    = 8;
      border-size      = 2;
      font             = "Hack Nerd Font 11";
      default-timeout  = 5000;
    };
  };

  # ---------- Hypridle ----------
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd     = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd            = "hyprlock";
      };
      listener = [
        { timeout = 300; on-timeout = "hyprlock"; }
        { timeout = 600; on-timeout = "hyprctl dispatch dpms off";
                         on-resume  = "hyprctl dispatch dpms on"; }
      ];
    };
  };

  # ---------- Rofi ----------
  programs.rofi = {
    enable   = true;
    package  = pkgs.rofi;
    terminal = "${pkgs.alacritty}/bin/alacritty";
    extraConfig = {
      modi               = "drun,run,window";
      show-icons         = true;
      drun-display-format = "{icon} {name}";
      disable-history    = false;
    };
  };
}
