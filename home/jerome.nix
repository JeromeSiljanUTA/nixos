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
			"Mod4+a" = "workspace a";
			"Mod4+s" = "workspace s";
			"Mod4+d" = "workspace d";
			"Mod4+f" = "workspace f";
			"Mod4+u" = "workspace u";
			"Mod4+i" = "workspace i";
			"Mod4+o" = "workspace o";
			"Mod4+p" = "workspace p";

			"Mod4+Shift+a" = "move container to workspace a";
			"Mod4+Shift+s" = "move container to workspace s";
			"Mod4+Shift+d" = "move container to workspace d";
			"Mod4+Shift+f" = "move container to workspace f";
			"Mod4+Shift+u" = "move container to workspace u";
			"Mod4+Shift+i" = "move container to workspace i";
			"Mod4+Shift+o" = "move container to workspace o";
			"Mod4+Shift+p" = "move container to workspace p";
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


  home.packages = with pkgs; [
	wofi
	grim
	slurp

	fzf
  ];
}
