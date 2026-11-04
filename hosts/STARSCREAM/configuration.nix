{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../common/desktop/sway.nix
    ../../common/hardware/android_adb.nix
    ../../common/hardware/scanner.nix
    ../../common/utils/utils.nix
  ];
  programs.nix-ld.enable = true;
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="0451", ATTR{idProduct}=="d00e", MODE="0666"
  '';

  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hibernate to a swapfile on the LUKS-encrypted btrfs root. Because the root
  # is already unlocked with a passphrase in initrd, the swapfile is encrypted
  # at rest and that same key is required to resume. systemd in stage 1 records
  # the swapfile's device and offset in the HibernateLocation EFI variable, so
  # no resume=/resume_offset= kernel parameters are needed.
  boot.initrd.systemd.enable = true;

  swapDevices = [
    {
      device = "/swapfile";
      # Must be at least the installed RAM for the hibernation image to fit.
      size = 16 * 1024;
    }
  ];

  networking.hostName = "STARSCREAM";
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
    brightnessctl
  ];

  services.openssh.enable = true;
  services.netbird.enable = true;

  # syncthing default ports: 22000/tcp (transfer), 22000/udp (quic), 21027/udp (discovery)
  # localsend: 53317/tcp (HTTPS API + transfer), 53317/udp (multicast discovery)
  networking.firewall = {
    allowedTCPPorts = [8912 22000 53317];
    allowedUDPPorts = [21027 22000 53317];
  };

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
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  services.blueman.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  system.stateVersion = "25.11";
}
