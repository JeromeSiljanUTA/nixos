{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    localsend
  ];

  programs.firefox = {
    profiles.default.settings = {
      "media.ffmpeg.vaapi.enabled" = true;
      "media.av1.enabled" = false;
    };
  };

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
