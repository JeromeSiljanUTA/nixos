{
  config,
  pkgs,
  ...
}: {
  programs.firefox = {
    profiles.default.settings = {
      "media.ffmpeg.vaapi.enabled" = true;
      "media.av1.enabled" = false;
    };
  };
}
