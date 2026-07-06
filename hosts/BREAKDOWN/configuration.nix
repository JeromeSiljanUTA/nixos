{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "BREAKDOWN"; 
  networking.wireless.iwd.enable = true;

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.jerome = {
    isNormalUser = true;
    description = "Jerome Siljan";
    extraGroups = [ "wheel" "scanner" "lp" ]; 
    packages = with pkgs; [];
  };

  programs.sway = {
  	enable = true;
  	wrapperFeatures.gtk = true;
  };

   environment.systemPackages = with pkgs; [
   	git
	neovim
	foot
	firefox
   ];

  services.openssh.enable = true;

  hardware.graphics = {
	enable = true;
  };

  system.stateVersion = "25.11"; 

}

