# Shared colour palettes. Every themed component reads its colours from here so
# adding a scheme or tweaking the gruvbox tones only happens in one place.
#
# To add a scheme: add an attribute set under this one with the same keys and
# select it through `myTheme.colorscheme`.
{
  gruvbox = {
    dark = {
      bg0 = "#282828";
      bg1 = "#3c3836";
      bg2 = "#504945";
      bg3 = "#665c54";
      bg4 = "#7c6f64";

      fg0 = "#fbf1c7";
      fg1 = "#ebdbb2";
      fg2 = "#d5c4a1";
      fg3 = "#bdae93";
      fg4 = "#a89984";

      red = "#fb4934";
      redSoft = "#cc241d";
      green = "#b8bb26";
      greenSoft = "#98971a";
      yellow = "#fabd2f";
      yellowSoft = "#d79921";
      blue = "#83a598";
      blueSoft = "#458588";
      purple = "#d3869b";
      purpleSoft = "#b16286";
      aqua = "#8ec07c";
      aquaSoft = "#689d6a";
      orange = "#fe8019";
      orangeSoft = "#d65d0e";
      gray = "#928374";
    };

    light = {
      bg0 = "#fbf1c7";
      bg1 = "#ebdbb2";
      bg2 = "#d5c4a1";
      bg3 = "#bdae93";
      bg4 = "#a89984";

      fg0 = "#282828";
      fg1 = "#3c3836";
      fg2 = "#504945";
      fg3 = "#665c54";
      fg4 = "#7c6f64";

      red = "#9d0006";
      redSoft = "#cc241d";
      green = "#79740e";
      greenSoft = "#98971a";
      yellow = "#b57614";
      yellowSoft = "#d79921";
      blue = "#076678";
      blueSoft = "#458588";
      purple = "#8f3f71";
      purpleSoft = "#b16286";
      aqua = "#427b58";
      aquaSoft = "#689d6a";
      orange = "#af3a03";
      orangeSoft = "#d65d0e";
      gray = "#928374";
    };
  };
}
