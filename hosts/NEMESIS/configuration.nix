{
  config,
  lib,
  pkgs,
  ...
}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];

  imports = [
    ./hardware-configuration.nix
  ];
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  networking.hostName = "NEMESIS";
  networking.firewall.checkReversePath = false;

  networking.firewall.allowedTCPPorts = [22 2222 3000 5000 8000 8001 8002 8084 8096 8123 9091 29170];
  networking.firewall.allowPing = true;

  networking.firewall.extraCommands = ''
    iptables -I DOCKER-USER -i docker0 -o wt0 -j DROP
  '';

  networking.nameservers = ["8.8.8.8" "8.8.4.4"];

  time.timeZone = "America/Chicago";

  users.users.jerome = {
    isNormalUser = true;
    description = "Jerome";
    extraGroups = ["wheel" "jerome"];
    home = "/home/jerome";
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      dns = ["8.8.8.8" "8.8.4.4"];
    };
  };

  # needed for gpu + docker
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.nvidia-container-toolkit.enable = true;

  services.xserver.xkb.layout = "us";

  services.openssh.enable = true;
  services.netbird.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    alejandra
    btrfs-progs
    coreutils
    cryptsetup
    docker
    emacs
    ffmpeg
    gcc
    git
    parted
    pciutils
    python3
    sshfs
    unixtools.top
    unzip
    uv
    wget
    zip

    neovim
    fzf
  ];

  system.stateVersion = "24.11";
}
