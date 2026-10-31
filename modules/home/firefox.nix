{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.apps.firefox;
  json = pkgs.formats.json { };

  forceInstalled = lib.mapAttrs (_: slug: {
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
    installation_mode = "force_installed";
  }) cfg.extensions;
in
{
  options.dotnix.apps.firefox = {
    enable = lib.mkEnableOption "firefox, configured through programs.firefox";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.firefox;
      defaultText = lib.literalExpression "pkgs.firefox";
      description = "Firefox package to install.";
    };

    profile = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "default";
        description = "Name of the managed profile, which is also made the default.";
      };
      path = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "9ojaf2g8.default";
        description = ''
          Directory under ~/.mozilla/firefox for the profile. Null uses the
          profile name. Set it to an existing directory to adopt that
          profile's bookmarks and logins instead of starting fresh.
        '';
      };
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.bool
          lib.types.int
          lib.types.str
        ]
      );
      default = { };
      example = {
        "browser.startup.page" = 3;
      };
      description = "about:config prefs written to the profile's user.js, merged over the built-in defaults.";
    };

    extensions = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        "uBlock0@raymondhill.net" = "ublock-origin";
      };
      description = ''
        Extensions force-installed by policy, as extension id to the slug in
        its addons.mozilla.org url. The id is the gecko id from the add-on's
        manifest, shown on about:support.
      '';
    };

    policies = lib.mkOption {
      type = json.type;
      default = { };
      description = "Extra enterprise policies merged over the built-in defaults.";
    };

    searchEngine = lib.mkOption {
      type = lib.types.str;
      default = "ddg";
      description = "Default search engine id.";
    };

    userChrome = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Contents of chrome/userChrome.css in the profile.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      inherit (cfg) package;
      # keep the legacy location so an existing ~/.mozilla profile is adopted
      configPath = lib.mkDefault ".mozilla/firefox";

      policies = lib.mkMerge [
        {
          DisableTelemetry = lib.mkDefault true;
          DisablePocket = lib.mkDefault true;
          DisableFirefoxStudies = lib.mkDefault true;
          DontCheckDefaultBrowser = lib.mkDefault true;
        }
        (lib.mkIf (cfg.extensions != { }) { ExtensionSettings = forceInstalled; })
        cfg.policies
      ];

      profiles.${cfg.profile.name} = {
        id = 0;
        isDefault = true;
        path = lib.mkIf (cfg.profile.path != null) cfg.profile.path;
        settings = {
          # restore the previous session instead of the home page
          "browser.startup.page" = lib.mkDefault 3;
          "privacy.donottrackheader.enabled" = lib.mkDefault true;
        }
        // cfg.settings;
        search = {
          default = cfg.searchEngine;
          force = true;
        };
        inherit (cfg) userChrome;
      };
    };
  };
}
