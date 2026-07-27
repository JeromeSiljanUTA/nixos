{
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;
    settings = {
      push.autoSetupRemote = true;
      user = {
        name = "Jerome Siljan";
        email = "JeromeSiljan@gmail.com";
      };
    };
  };
}
