{
  config,
  lib,
  pkgs,
  ...
}: let
  theme = config.myTheme;
  notify = pkgs.libnotify;
in {
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    # The CSS file is a symlink through the active theme directory so the
    # `theme` command can swap it and reload waybar with SIGUSR2.
    style = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.local/state/theme/current/waybar.css";

    settings = [
      {
        layer = "bottom";
        position = "bottom";
        height = theme.barHeight;
        spacing = 4;

        modules-left = ["sway/workspaces" "sway/mode"];
        modules-center = ["clock"];
        modules-right = ["custom/theme" "backlight" "battery" "network" "pulseaudio" "tray"];

        "sway/workspaces" = {
          format = "{name}";
          on-click = "activate";
        };

        "sway/mode" = {
          format = "{}";
        };

        "sway/window" = {
          format = "{}";
          max-length = 64;
        };

        clock = {
          format = "{:%a %b %d  %H:%M}";
          tooltip-format = "{:%A, %B %d, %Y}";
        };

        "custom/theme" = {
          exec = "if [ \"$(cat $HOME/.local/state/theme/mode)\" = dark ]; then echo 󰖔; else echo 󰖙; fi";
          interval = 2;
          tooltip = true;
          tooltip-format = "Toggle light/dark theme";
          on-click = "${theme.command}/bin/theme toggle";
        };

        backlight = {
          format = "{icon} {percent}%";
          format-icons = ["󰃞" "󰃟" "󰃠"];
          on-scroll-up = "brightnessctl set 5%+";
          on-scroll-down = "brightnessctl set 5%-";
        };

        battery = {
          interval = 30;
          states = {
            warning = 20;
            critical = 10;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂅 {capacity}%";
          format-plugged = "󰂅 {capacity}%";
          format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
          tooltip-format = "{timeTo}\n{capacity}%";
          events = {
            "on-discharging-warning" = "${notify}/bin/notify-send -u normal -a battery 'Battery low' 'Battery is under 20%'";
            "on-discharging-critical" = "${notify}/bin/notify-send -u critical -a battery 'Battery critical' 'Battery is under 10%'";
          };
        };

        network = {
          format-wifi = "󰤨 {essid}";
          format-ethernet = "󰈀 {ifname}";
          format-linked = "󰈀 {ifname} (no IP)";
          format-disconnected = "󰤭";
          tooltip-format = "{ifname} via {gwaddr}";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 muted";
          format-icons = {
            default = ["󰕿" "󰖀" "󰕾"];
          };
          on-click = "pwvucontrol";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };

        tray = {
          spacing = 8;
        };
      }
    ];
  };
}
