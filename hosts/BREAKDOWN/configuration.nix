{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "BREAKDOWN";
  networking.wireless.iwd.enable = true;

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.jerome = {
    isNormalUser = true;
    description = "Jerome Siljan";
    extraGroups = ["wheel" "video"];
    packages = with pkgs; [];
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  environment.systemPackages = with pkgs; [
    tree
    git
    neovim
    foot
    firefox
    brightnessctl
  ];

  services.openssh.enable = true;
  services.netbird.enable = true;

  security.polkit.enable = true;

  hardware.graphics = {
    enable = true;
  };

  networking.firewall.allowedTCPPorts = [8912];

  system.stateVersion = "25.11";
}
