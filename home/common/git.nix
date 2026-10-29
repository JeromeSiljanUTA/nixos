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
      # Token is read at runtime from sops, falls back to prompt
      credential.helper = "!f() { [ -r /run/secrets/gitea_token_laptops ] || exit 0; echo username=jerome; echo \"password=$(cat /run/secrets/gitea_token_laptops)\"; }; f";
    };
  };
}
