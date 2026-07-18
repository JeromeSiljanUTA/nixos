{ config, pkgs, ... }:

{
  home.username = "jerome";
  home.homeDirectory = "/home/jerome";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.git.enable = true;

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

		startup = [
			# nothing on startup
		];
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
	extraLuaConfig = builtins.readFile ./configs/nvim/init.lua;
  };

  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = "32.8";
    longitude = "-96.9";
    temperature = {
        night = 2000;
    };
  };


  home.packages = with pkgs; [
    # wayland
	wofi
	grim
	slurp
    wdisplays
    pwvucontrol

	fzf
  ];
}
