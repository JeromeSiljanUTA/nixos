{
  config,
  pkgs,
  ...
}: {
  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = "32.8";
    longitude = "-96.9";
    temperature = {
      night = 3000;
    };
  };
}
