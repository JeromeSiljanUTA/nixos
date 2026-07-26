{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs;
    lib.mkAfter [
      sane-backends
      simple-scan
    ];

  users.users.jerome.extraGroups = lib.mkAfter ["scanner" "lp"];

  hardware.sane.enable = true;
}
