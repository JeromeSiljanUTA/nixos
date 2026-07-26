{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs;
    lib.mkAfter [
      tree
      git
      neovim
      fzf
      ffmpeg

      # system
      cryptsetup
      parted
      pciutils
      btrfs-progs
      unixtools.top
      unzip
      zip
      wget

      # formatters
      alejandra
      stylua
    ];
}
