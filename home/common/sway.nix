{
  config,
  lib,
  pkgs,
  ...
}: let
  theme = config.myTheme;
in {
  wayland.windowManager.sway = {
    enable = true;

    # Static colours and bar emitted by home-manager are overridden by this
    # include; the file behind it is swapped by the `theme` command.
    extraConfig = "include ${config.home.homeDirectory}/.local/state/theme/current/sway";

    config = {
      modifier = "Mod4"; # Super

      terminal = "footclient";
      menu = "wofi --show drun";

      # Waybar replaces the stock swaybar.
      bars = [];

      fonts = {
        names = [theme.uiFont theme.iconFont];
        size = 10.0;
      };

      startup = [
        {command = "${theme.command}/bin/theme apply";}
      ];

      keybindings = {
        "Mod4+Tab" = "workspace back_and_forth";
        "Mod4+Return" = "exec footclient";
        "Mod4+Shift+c" = "kill";
        "Mod4+n" = "exec wofi --show drun";
        "Mod4+w" = "layout toggle tabbed split";
        "Mod4+Shift+t" = "exec ${theme.command}/bin/theme toggle";

        # workspaces (names stay numeric so sway keeps home-row order; the bar
        # strips the number and shows only the letter)
        "Mod4+a" = "workspace 1:a";
        "Mod4+s" = "workspace 2:s";
        "Mod4+d" = "workspace 3:d";
        "Mod4+f" = "workspace 4:f";
        "Mod4+u" = "workspace 5:u";
        "Mod4+i" = "workspace 6:i";
        "Mod4+o" = "workspace 7:o";
        "Mod4+p" = "workspace 8:p";

        "Mod4+Shift+a" = "move container to workspace 1:a";
        "Mod4+Shift+s" = "move container to workspace 2:s";
        "Mod4+Shift+d" = "move container to workspace 3:d";
        "Mod4+Shift+f" = "move container to workspace 4:f";
        "Mod4+Shift+u" = "move container to workspace 5:u";
        "Mod4+Shift+i" = "move container to workspace 6:i";
        "Mod4+Shift+o" = "move container to workspace 7:o";
        "Mod4+Shift+p" = "move container to workspace 8:p";

        "Mod4+h" = "focus left";
        "Mod4+l" = "focus right";
        "Mod4+j" = "focus down";
        "Mod4+k" = "focus up";

        "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
        "XF86MonBrightnessUp" = "exec brightnessctl set 5%+";

        "Mod4+Print" = ''exec sh -c 'grim -g "$(slurp -d)" - | wl-copy -t image/png' '';

        # kpmenu (keepass)
        "Mod4+v" = "exec ${pkgs.kpmenu}/bin/kpmenu view";
      };

      output = {
        "*" = {
          bg = "${./wallpapers/Toronto-KingSt-Datacenter-1.jpg} fill";
        };
        DP-3 = {
          scale = "1.2";
        };
        DP-6 = {
          scale = "1.2";
        };
        eDP-1 = {
          scale = "1";
        };
      };
    };
  };
}
