{...}: {
  # The stylesheet is provided by theme.nix as a symlink to the active theme.
  xdg.configFile."wofi/config".text = ''
    show=drun
    prompt=Search
    columns=1
    lines=8
    width=500
    height=420
    location=center
    orientation=vertical
    halign=center
    line_wrap=word
    dynamic_lines=true
    matching=fuzzy
  '';
}
