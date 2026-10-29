{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../common/desktop/sway.nix
    ../../common/utils/utils.nix
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

  environment.systemPackages = with pkgs; [
    firefox
    brightnessctl
  ];

  services.openssh.enable = true;
  services.netbird.enable = true;

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/age-key.txt";
    secrets = {
      gitea_token_laptops = {
        owner = "jerome";
        mode = "0400";
      };
    };
  };

  security.polkit.enable = true;

  hardware.graphics = {
    enable = true;
  };

  networking.firewall.allowedTCPPorts = [8912 8913];

  system.stateVersion = "25.11";
}
