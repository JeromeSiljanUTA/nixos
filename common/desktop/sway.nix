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
      swaybg
      wdisplays
      wofi
    ];

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # Needed so the runtime light/dark toggle can update GTK apps through
  # gsettings.
  programs.dconf.enable = true;
}
