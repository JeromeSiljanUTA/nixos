{
  config,
  pkgs,
  ...
}: {
  home.username = "jerome";
  home.homeDirectory = "/home/jerome";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  wayland.windowManager.sway = {
    enable = true;

    config = {
      modifier = "Mod4"; # Super

      terminal = "foot";
      menu = "wofi --show drun";

      keybindings = {
        "Mod4+Tab" = "workspace back_and_forth";
        "Mod4+Return" = "exec foot";
        "Mod4+Shift+c" = "kill";
        "Mod4+n" = "exec wofi --show drun";
        "Mod4+w" = "layout toggle tabbed split";

        # workspaces
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
      };

      output = {
        DP-3 = {
          scale = "1";
        };
        eDP-1 = {
          scale = "1";
        };
      };
    };
  };

  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_TYPE = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
  };

  programs.neovim = {
    enable = true;
    initLua = builtins.readFile ./configs/nvim/init.lua;
  };

  programs.git = {
    enable = true;
    settings = {
      push.autoSetupRemote = true;
      user = {
        name = "Jerome Siljan";
        email = "JeromeSiljan@gmail.com";
      };
    };
  };

  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = "32.8";
    longitude = "-96.9";
    temperature = {
      night = 3000;
    };
  };

  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "IBM Plex Mono:size=10";
        dpi-aware = "yes";
        initial-color-theme = "light";
      };
      colors-light = {
        foreground = "3c3836";
        background = "fbf1c7";

        regular0 = "fbf1c7"; # black
        regular1 = "cc241d"; # red
        regular2 = "98971a"; # green
        regular3 = "d79921"; # yellow
        regular4 = "458588"; # blue
        regular5 = "b16286"; # magenta
        regular6 = "689d6a"; # cyan
        regular7 = "7c6f64"; # white

        bright0 = "928374";
        bright1 = "9d0006";
        bright2 = "79740e";
        bright3 = "b57614";
        bright4 = "076678";
        bright5 = "8f3f71";
        bright6 = "427b58";
        bright7 = "3c3836";
      };
    };
  };

  home.packages = with pkgs; [
    # wayland
    wofi
    grim
    slurp
    wdisplays
    pwvucontrol

    # formatters
    alejandra
    stylua

    ibm-plex

    fzf
  ];
}
