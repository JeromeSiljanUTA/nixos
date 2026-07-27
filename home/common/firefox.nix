{
  config,
  pkgs,
  ...
}: {
  programs.firefox = {
    enable = true;

    profiles.default = {
      id = 0;
      isDefault = true;

      search = {
        default = "ddg";
        force = true;
      };

      settings = {
        # Blank homepage
        "browser.startup.homepage" = "about:blank";
        "browser.newtabpage.enabled" = false;

        # Hide bookmarks toolbar
        "browser.toolbars.bookmarks.visibility" = "never";

        # Optional privacy tweaks
        "browser.urlbar.suggest.bookmark" = false;
        "browser.urlbar.suggest.history" = true;
        "browser.urlbar.suggest.searches" = true;
      };

      extensions = {
        force = true;
        packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          sponsorblock
          dearrow
          multi-account-containers
        ];
      };
    };
  };
}
