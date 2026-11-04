{
  config,
  lib,
  ...
}: let
  cfg = config.myHibernate;
in {
  options.myHibernate = {
    swapSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 16 * 1024;
      description = ''
        Size of the hibernation swapfile in MiB (1024×1024 bytes). This must be
        at least the installed RAM for the hibernation image to fit.
      '';
    };
  };

  config = {
    # Hibernate to a swapfile on the LUKS-encrypted btrfs root. The root is
    # unlocked with a passphrase in initrd, so the swapfile is encrypted at rest
    # and that same key is required to resume. systemd in stage 1 records the
    # swapfile's device and offset in the HibernateLocation EFI variable, so no
    # resume=/resume_offset= kernel parameters are needed.
    boot.initrd.systemd.enable = true;

    swapDevices = [
      {
        device = "/swapfile";
        size = cfg.swapSize;
      }
    ];
  };
}
