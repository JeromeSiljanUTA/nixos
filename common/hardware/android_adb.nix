{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs;
    lib.mkAfter [
      pkgs.android-tools
    ];

  users.users.jerome.extraGroups = lib.mkAfter ["adbusers"];
}
