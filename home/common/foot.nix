{
  config,
  pkgs,
  ...
}: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "IBM Plex Mono:size=8";
        dpi-aware = "yes";
        initial-color-theme = "light";
      };
      colors-light = {
        foreground = "3c3836";
        background = "fbf1c7";

        regular0 = "fbf1c7"; # black
        regular1 = "cc241d"; # red
        regular2 = "98971a"; # green
        regular3 = "d79921"; # yellow
        regular4 = "458588"; # blue
        regular5 = "b16286"; # magenta
        regular6 = "689d6a"; # cyan
        regular7 = "7c6f64"; # white

        bright0 = "928374";
        bright1 = "9d0006";
        bright2 = "79740e";
        bright3 = "b57614";
        bright4 = "076678";
        bright5 = "8f3f71";
        bright6 = "427b58";
        bright7 = "3c3836";
      };
    };
  };
}
