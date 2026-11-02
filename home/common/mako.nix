{
  config,
  ...
}: {
  services.mako = {
    enable = true;

    # Colours live in the active theme directory. Mako resolves the include on
    # every reload, so `theme` switching is just `makoctl reload`.
    extraConfig = "include=${config.home.homeDirectory}/.local/state/theme/current/mako";
  };
}
