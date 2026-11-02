{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./common/firefox.nix
    ./common/foot.nix
    ./common/gammastep.nix
    ./common/git.nix
    ./common/kpmenu.nix
    ./common/mako.nix
    ./common/sway.nix
    ./common/theme.nix
    ./common/waybar.nix
    ./common/wofi.nix
  ];
  home.username = "jerome";
  home.homeDirectory = "/home/jerome";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

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

  xdg.userDirs = {
    enable = true;
    createDirectories = false;

    desktop = "$HOME/desktop";
    documents = "$HOME/documents";
    download = "$HOME/downloads";
    music = "$HOME/music";
    pictures = "$HOME/pictures";
    publicShare = "$HOME/public";
    templates = "$HOME/templates";
    videos = "$HOME/videos";
  };

  home.packages = with pkgs; [
    ibm-plex
  ];
}
