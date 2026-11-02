{
  config,
  lib,
  pkgs,
  ...
}: let
  schemes = import ./lib/theme.nix;
  cfg = config.myTheme;
  palette = schemes.${cfg.colorscheme};
  hex = lib.removePrefix "#";
  mkColors = mode: let
    p = palette.${mode};
  in {
    foreground = hex p.fg1;
    background = hex p.bg0;

    regular0 = hex p.bg0; # black
    regular1 = hex p.redSoft; # red
    regular2 = hex p.greenSoft; # green
    regular3 = hex p.yellowSoft; # yellow
    regular4 = hex p.blueSoft; # blue
    regular5 = hex p.purpleSoft; # magenta
    regular6 = hex p.aquaSoft; # cyan
    regular7 = hex p.fg4; # white

    bright0 = hex p.gray;
    bright1 = hex p.red;
    bright2 = hex p.green;
    bright3 = hex p.yellow;
    bright4 = hex p.blue;
    bright5 = hex p.purple;
    bright6 = hex p.aqua;
    bright7 = hex p.fg1;
  };
in {
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        # The Mono symbols variant keeps fallback icon glyphs aligned to the terminal cell grid.
        font = "${cfg.monoFont}:size=8, ${cfg.iconFont} Mono:size=8";
        dpi-aware = "yes";
        initial-color-theme = cfg.defaultMode;
      };
      colors-light = mkColors "light";
      colors-dark = mkColors "dark";
    };
  };
}
