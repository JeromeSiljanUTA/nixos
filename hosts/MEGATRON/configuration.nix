{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../common/desktop/sway.nix
    ../../common/hardware/hibernate.nix
    ../../common/utils/utils.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Must be at least the installed RAM for the hibernation image to fit.
  myHibernate.swapSize = 16 * 1024;

  networking.hostName = "MEGATRON";

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.jerome = {
    isNormalUser = true;
    description = "Jerome Siljan";
    extraGroups = ["wheel" "video"];
    packages = with pkgs; [];
  };

  programs.sway = {
    extraOptions = ["--unsupported-gpu"];
  };

  environment.systemPackages = with pkgs; [
    firefox
  ];

  services.openssh.enable = true;
  services.netbird.enable = true;

  security.polkit.enable = true;

  # nvidia
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  system.stateVersion = "25.11";
}
