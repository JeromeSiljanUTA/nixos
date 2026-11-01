{
  config,
  pkgs,
  ...
}: {
  programs.kpmenu = {
    enable = true;
    database = "~/keepass/Database.kdbx";
  };
}
