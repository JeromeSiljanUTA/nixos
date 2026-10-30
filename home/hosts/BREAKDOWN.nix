{
  config,
  pkgs,
  ...
}: {
  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        KNOCKOUT.id = "6MHLKYN-3OV6AVC-A3Y5ZQZ-DNIWSK3-B6TEZUT-U6KG77T-UDYNLJI-S5ZLGQT";
      };
      folders = {
        keepass = {
          path = "~/keepass";
          devices = ["KNOCKOUT"];
        };
      };
    };
  };
}
