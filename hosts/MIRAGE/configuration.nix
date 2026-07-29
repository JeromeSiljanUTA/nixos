{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../common/utils/utils.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  # enp1s0 is the built in realtek NIC
  # enp2s0 is the m.2 intel NIC

  networking = {
    hostName = "MIRAGE";

    useDHCP = false;

    interfaces.enp1s0.useDHCP = true;

    interfaces.enp2s0.ipv4.addresses = [
      {
        address = "192.168.10.1";
        prefixLength = 24;
      }
    ];

    nat = {
      enable = true;
      externalInterface = "enp1s0";
      internalInterfaces = ["enp2s0"];
    };

    firewall.enable = true;
  };

  services.dnsmasq = {
    enable = true;

    settings = {
      interface = "enp2s0";
      dhcp-range = "192.168.10.100,192.168.10.200,12h";

      dhcp-option = [
        "option:router,192.168.10.1"
        "option:dns-server,192.168.10.1"
      ];

      server = [
        "1.1.1.1"
        "1.0.0.1"
      ];
    };
  };

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.jerome = {
    isNormalUser = true;
    description = "Jerome Siljan";
    extraGroups = ["wheel"];
    packages = with pkgs; [];
  };

  environment.systemPackages = with pkgs; [
  ];

  services.openssh.enable = true;
  services.netbird.enable = true;

  system.stateVersion = "25.11";
}
