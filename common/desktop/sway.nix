{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs;
    lib.mkAfter [
      foot
      grim
      pwvucontrol
      slurp
      wdisplays
      wofi
    ];
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
}
