{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myTheme;
  schemes = import ./lib/theme.nix;
  scheme = schemes.${cfg.colorscheme};
  modes = ["light" "dark"];

  quote = s: ''"${s}"'';

  swayColors = p: ''
    client.focused          ${p.aqua} ${p.bg2} ${p.fg0} ${p.orange} ${p.bg2}
    client.focused_inactive ${p.bg2} ${p.bg1} ${p.fg4} ${p.bg2} ${p.bg1}
    client.unfocused        ${p.bg2} ${p.bg0} ${p.gray} ${p.bg0} ${p.bg0}
    client.urgent           ${p.red} ${p.redSoft} ${p.fg0} ${p.red} ${p.redSoft}
    client.placeholder      ${p.bg0} ${p.bg0} ${p.fg1} ${p.bg0} ${p.bg0}
    client.background       ${p.bg0}
  '';

  waybarCss = p: ''
    @define-color bg0 ${p.bg0};
    @define-color bg1 ${p.bg1};
    @define-color bg2 ${p.bg2};
    @define-color bg3 ${p.bg3};
    @define-color bg4 ${p.bg4};
    @define-color fg0 ${p.fg0};
    @define-color fg1 ${p.fg1};
    @define-color fg2 ${p.fg2};
    @define-color fg3 ${p.fg3};
    @define-color fg4 ${p.fg4};
    @define-color red ${p.red};
    @define-color green ${p.green};
    @define-color yellow ${p.yellow};
    @define-color blue ${p.blue};
    @define-color purple ${p.purple};
    @define-color aqua ${p.aqua};
    @define-color orange ${p.orange};
    @define-color gray ${p.gray};

    * {
      font-family: ${quote cfg.uiFont}, ${quote cfg.iconFont};
      font-size: 13px;
      min-height: 0;
    }

    window#waybar {
      background-color: @bg0;
      color: @fg1;
      border-top: 2px solid @bg3;
    }

    #workspaces button {
      padding: 0 9px;
      color: @fg4;
      background: transparent;
      border-radius: 6px;
    }

    #workspaces button.visible {
      color: @fg1;
    }

    #workspaces button.focused {
      color: @bg0;
      background-color: @aqua;
    }

    #workspaces button.urgent {
      color: @bg0;
      background-color: @red;
    }

    #mode, #window, #clock, #battery, #network, #pulseaudio, #tray, #custom-theme {
      padding: 0 10px;
      color: @fg1;
    }

    #window {
      color: @fg4;
    }

    #battery.warning {
      color: @yellow;
    }

    #battery.critical {
      color: @red;
    }

    #battery.charging, #battery.plugged {
      color: @green;
    }

    #network.disconnected {
      color: @red;
    }

    #pulseaudio.muted {
      color: @fg4;
    }

    tooltip {
      background-color: @bg1;
      border: 1px solid @aqua;
      border-radius: 6px;
    }

    tooltip label {
      color: @fg1;
    }
  '';

  wofiCss = p: ''
    @define-color bg ${p.bg0};
    @define-color bg1 ${p.bg1};
    @define-color fg ${p.fg1};
    @define-color fg-dim ${p.fg4};
    @define-color accent ${p.aqua};
    @define-color accent-fg ${p.bg0};

    * {
      font-family: ${quote cfg.uiFont}, ${quote cfg.iconFont};
      font-size: 13px;
    }

    window {
      background-color: transparent;
      color: @fg;
      border-radius: 0;
      box-shadow: none;
    }

    #outer-box {
      background-color: @bg;
      border: 2px solid @accent;
      border-radius: 10px;
      box-shadow: none;
    }

    #input {
      margin: 8px;
      padding: 8px;
      border: 1px solid @bg1;
      border-radius: 6px;
      background-color: @bg1;
      color: @fg;
      box-shadow: none;
      outline: none;
    }

    #inner-box {
      background: transparent;
    }

    #entry {
      margin: 2px 0;
      padding: 6px;
      border-radius: 0;
    }

    #entry:selected {
      background-color: alpha(@accent, 0.3);
      color: @fg;
    }

    #text {
      color: @fg;
    }

    #text:selected {
      color: @fg;
    }

    #scroll {
      margin: 0;
    }
  '';

  makoConfig = p: ''
    font=${cfg.uiFont} 11
    background-color=${p.bg1}F2
    text-color=${p.fg1}
    border-color=${p.aqua}
    border-size=2
    border-radius=8
    padding=10
    margin=10
    width=340
    height=160
    anchor=top-right
    default-timeout=8000
    ignore-timeout=0
    max-visible=3
    icons=1
    markup=1
    format=<b>%s</b>\n%b
  '';

  gtkIni = mode: let
    dark = mode == "dark";
  in ''
    [Settings]
    gtk-theme-name=Gruvbox-${if dark then "Dark" else "Light"}
    gtk-icon-theme-name=Adwaita
    gtk-font-name=${cfg.uiFont} 11
    gtk-application-prefer-dark-theme=${if dark then "true" else "false"}
    gtk-interface-color-scheme=${if dark then "2" else "3"}
    gtk-cursor-theme-name=Adwaita
    gtk-cursor-theme-size=24
  '';

  themeFiles = mode: let
    p = scheme.${mode};
  in {
    "theme/${cfg.colorscheme}/${mode}/sway".text = swayColors p;
    "theme/${cfg.colorscheme}/${mode}/waybar.css".text = waybarCss p;
    "theme/${cfg.colorscheme}/${mode}/wofi.css".text = wofiCss p;
    "theme/${cfg.colorscheme}/${mode}/mako".text = makoConfig p;
    "theme/${cfg.colorscheme}/${mode}/gtk-3.0/settings.ini".text = gtkIni mode;
    "theme/${cfg.colorscheme}/${mode}/gtk-4.0/settings.ini".text = gtkIni mode;
  };

  themeRoot = "${config.home.homeDirectory}/.config/theme/${cfg.colorscheme}";
  stateDir = "${config.home.homeDirectory}/.local/state/theme";

  themeScript = pkgs.writeShellApplication {
    name = "theme";
    runtimeInputs = with pkgs; [
      coreutils
      procps
      sway
      mako
      glib
      libnotify
    ];
    text = ''
      state_dir="${stateDir}"
      theme_root="${themeRoot}"
      mkdir -p "$state_dir"
      if [ ! -f "$state_dir/mode" ]; then
        printf '%s\n' "${cfg.defaultMode}" > "$state_dir/mode"
      fi
      stored="$(cat "$state_dir/mode")"
      case "$stored" in
        light|dark) ;;
        *)
          stored="${cfg.defaultMode}"
          printf '%s\n' "$stored" > "$state_dir/mode"
          ;;
      esac

      action="''${1:-toggle}"
      case "$action" in
        toggle)
          if [ "$stored" = dark ]; then
            mode=light
          else
            mode=dark
          fi
          ;;
        apply|reload)
          mode="$stored"
          ;;
        set)
          mode="''${2:-}"
          case "$mode" in
            light|dark) ;;
            *)
              echo "usage: theme set <light|dark>" >&2
              exit 2
              ;;
          esac
          ;;
        *)
          echo "usage: theme [toggle|apply|set <light|dark>]" >&2
          exit 2
          ;;
      esac

      printf '%s\n' "$mode" > "$state_dir/mode"
      ln -sfn "$theme_root/$mode" "$state_dir/current"

      if [ -n "''${SWAYSOCK:-}" ] && command -v swaymsg >/dev/null 2>&1; then
        swaymsg reload >/dev/null 2>&1 || true
      fi

      pkill -SIGUSR2 -x waybar >/dev/null 2>&1 || true
      makoctl reload >/dev/null 2>&1 || true

      foot_signal() {
        if [ "$mode" = dark ]; then
          pkill -SIGUSR1 -x foot >/dev/null 2>&1 || true
        else
          pkill -SIGUSR2 -x foot >/dev/null 2>&1 || true
        fi
      }

      if [ "$action" = apply ] || [ "$action" = reload ]; then
        # The foot server may still be starting when the session begins, so
        # retry the signal until it is definitely running.
        for _ in $(seq 1 30); do
          if pgrep -x foot >/dev/null 2>&1; then
            foot_signal
          fi
          sleep 0.1
        done
      else
        foot_signal
      fi

      if command -v gsettings >/dev/null 2>&1; then
        mode_title=Light
        [ "$mode" = dark ] && mode_title=Dark
        gsettings set org.gnome.desktop.interface color-scheme "prefer-$mode" >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface gtk-theme "Gruvbox-$mode_title" >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface icon-theme Adwaita >/dev/null 2>&1 || true
      fi

      if [ "$action" = toggle ]; then
        notify-send -a theme "Theme" "Switched to $mode" >/dev/null 2>&1 || true
      fi
    '';
  };
in {
  options.myTheme = {
    colorscheme = lib.mkOption {
      type = lib.types.enum (builtins.attrNames schemes);
      default = "gruvbox";
      description = "Colour scheme to use.";
    };

    defaultMode = lib.mkOption {
      type = lib.types.enum ["light" "dark"];
      default = "light";
      description = "Theme mode used when no runtime preference is stored.";
    };

    uiFont = lib.mkOption {
      type = lib.types.str;
      default = "IBM Plex Sans";
      description = "Font used by the bar, menus and notifications.";
    };

    monoFont = lib.mkOption {
      type = lib.types.str;
      default = "IBM Plex Mono";
      description = "Font used by terminals.";
    };

    iconFont = lib.mkOption {
      type = lib.types.str;
      default = "Symbols Nerd Font";
      description = "Fallback font providing icons.";
    };

    barHeight = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
      description = "Waybar height in pixels.";
    };

    command = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "The theme switching command.";
    };
  };

  config = {
    myTheme.command = themeScript;

    home.packages = [
      pkgs.gruvbox-gtk-theme
      pkgs.nerd-fonts.symbols-only
      pkgs.adwaita-icon-theme
    ];

    xdg.configFile =
      (builtins.foldl' (acc: mode: acc // themeFiles mode) {} modes)
      // {
        "wofi/style.css".source =
          config.lib.file.mkOutOfStoreSymlink "${stateDir}/current/wofi.css";
        "gtk-3.0/settings.ini".source =
          config.lib.file.mkOutOfStoreSymlink "${stateDir}/current/gtk-3.0/settings.ini";
        "gtk-4.0/settings.ini".source =
          config.lib.file.mkOutOfStoreSymlink "${stateDir}/current/gtk-4.0/settings.ini";
      };

    home.activation.seedTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
      state_dir="${stateDir}"
      theme_root="${themeRoot}"
      mkdir -p "$state_dir"
      if [ ! -f "$state_dir/mode" ]; then
        printf '%s\n' "${cfg.defaultMode}" > "$state_dir/mode"
      fi
      mode="$(cat "$state_dir/mode")"
      case "$mode" in
        light|dark) ;;
        *)
          mode="${cfg.defaultMode}"
          printf '%s\n' "$mode" > "$state_dir/mode"
          ;;
      esac
      ln -sfn "$theme_root/$mode" "$state_dir/current"
    '';
  };
}
