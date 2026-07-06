{ config, pkgs, ... }:

{
  home.username = "jerome";
  home.homeDirectory = "/home/jerome";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.git.enable = true;
}
