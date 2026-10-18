# Woodpecker CI for NEMESIS.
#
# Design notes (see DESIGN.md):
# - Server uses the stock nixpkgs module.
# - Agent is a CUSTOM systemd service, NOT services.woodpecker-agents.
#   Reason: the stock agent runs as DynamicUser with ProtectSystem=strict,
#   PrivateUsers, NoNewPrivileges, etc. That sandbox cannot drive
#   `nixos-rebuild switch` on the host (needs root + writable /nix,/etc,systemd).
#   We run the agent binary as a stable `woodpecker` user with sudoers
#   scoped to nixos-rebuild only. The pipeline uses the `local` backend.
#
# Secrets: sops-nix renders files; both services consume them via
# EnvironmentFile (KEY=value format), not as raw env values.
{
  config,
  lib,
  pkgs,
  ...
}: let
  ciUser = "woodpecker";
  # HTTP UI port (behind nginx) and the separate gRPC port the agent dials.
  serverHttpAddr = "127.0.0.1:8003";
  serverGrpcAddr = "127.0.0.1:9000";
  agentHealthAddr = "127.0.0.1:8004";

  # sops.placeholder.<name> expands to the secret's VALUE (not its path).
  # Using .path here would write the literal path into the env file, which is
  # why the server sent an invalid Gitea client id and the agent failed to auth.
  agentSecret = config.sops.placeholder.woodpecker_agent_secret;
  giteaClient = config.sops.placeholder.woodpecker_gitea_client_id;
  giteaSecret = config.sops.placeholder.woodpecker_gitea_client_secret;

  # Stable wrapper in a fixed path. Paths under /nix/store or /run/current-system
  # are resolved by the kernel before sudo matching, so pinning them in sudoers
  # is fragile. Instead, sudoers permits ONLY this root-owned wrapper, which
  # hardcodes the actual rebuild invocation. The CI pipeline calls the wrapper.
  rebuildWrapper = pkgs.writeShellScript "woodpecker-nixos-rebuild" ''
    set -eu
    # Nix refuses git/plain dirs it doesn't own; mark the checkout safe.
    export HOME=/var/lib/woodpecker
    export GIT_CONFIG_COUNT=1
    export GIT_CONFIG_KEY_0=safe.directory
    export GIT_CONFIG_VALUE_0='*'
    # Rebuild from the flake at the CURRENT working directory (the CI checkout).
    # sudo preserves cwd, so `$PWD` is the agent's workspace.
    flake="$PWD#NEMESIS"
    exec ${config.system.path}/bin/nixos-rebuild switch --flake "$flake"
  '';
  rebuildWrapperPath = "/run/woodpecker/rebuild";
in {
  # Expose the wrapper as a REAL root-owned file (not a symlink) at a fixed
  # path. sudo canonicalizes symlinks against the store before matching, which
  # would break the sudoers rule; a regular file avoids that.
  systemd.tmpfiles.rules = [
    "C+ ${rebuildWrapperPath} 0755 root root - ${rebuildWrapper}"
  ];
  # --- scoped rebuild user -------------------------------------------------
  users.users.${ciUser} = {
    isSystemUser = true;
    group = ciUser;
    home = "/var/lib/woodpecker";
    createHome = true;
  };
  users.groups.${ciUser} = {};

  security.sudo.extraRules = [
    {
      users = [ciUser];
      commands = [
        {
          # Only the wrapper; no arbitrary args.
          command = rebuildWrapperPath;
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # --- sops templates (secret files -> env files) --------------------------
  # Group-readable by the `woodpecker` group; both services join that group so
  # they can read the rendered env files even under systemd hardening.
  sops.templates."woodpecker-server.env" = {
    content = ''
      WOODPECKER_AGENT_SECRET=${agentSecret}
      WOODPECKER_GITEA_CLIENT=${giteaClient}
      WOODPECKER_GITEA_SECRET=${giteaSecret}
    '';
    owner = "root";
    group = ciUser;
    mode = "0440";
  };

  sops.templates."woodpecker-agent.env" = {
    content = ''
      WOODPECKER_AGENT_SECRET=${agentSecret}
    '';
    owner = ciUser;
    group = ciUser;
    mode = "0400";
  };

  # --- server (stock module) ----------------------------------------------
  # The stock server module runs as DynamicUser; give it the CI group so it
  # can read the root-owned, group-readable env template.
  systemd.services.woodpecker-server.serviceConfig.SupplementaryGroups = [ciUser];

  services.woodpecker-server = {
    enable = true;
    environmentFile = config.sops.templates."woodpecker-server.env".path;
    environment = {
      WOODPECKER_OPEN = "true";
      WOODPECKER_ADMIN = "jerome";
      WOODPECKER_HOST = "http://ci.nemesis.home.arpa";
      WOODPECKER_SERVER_ADDR = serverHttpAddr;
      # Agents speak gRPC to the server on this address.
      WOODPECKER_GRPC_ADDR = serverGrpcAddr;
      WOODPECKER_GITEA = "true";
      WOODPECKER_GITEA_URL = "http://git.nemesis.home.arpa";
    };
  };

  # --- agent (custom, unsandboxed, local backend) --------------------------
  systemd.services.woodpecker-agent = {
    description = "Woodpecker Agent (local backend)";
    wantedBy = ["multi-user.target"];
    # Unit-level ordering/deps (these belong in [Unit], not [Service]).
    after = ["network-online.target" "woodpecker-server.service" "sops-install-secrets.service"];
    wants = ["network-online.target" "woodpecker-server.service"];
    requires = ["sops-install-secrets.service"];
    environment = {
      # Agent dials the server's gRPC port, not the HTTP UI port.
      WOODPECKER_SERVER = serverGrpcAddr;
      WOODPECKER_BACKEND = "local";
      WOODPECKER_MAX_WORKFLOWS = "1";
      # Avoid colliding with Gitea on :3000.
      WOODPECKER_HEALTHCHECK_ADDR = agentHealthAddr;
    };
    serviceConfig = {
      User = ciUser;
      Group = ciUser;
      EnvironmentFile = config.sops.templates."woodpecker-agent.env".path;
      ExecStart = "${pkgs.woodpecker-agent}/bin/woodpecker-agent";
      Restart = "on-failure";
      RestartSec = 15;
      # Deliberately NOT heavily sandboxed: needs to run nixos-rebuild.
      # NoNewPrivileges must stay false so sudo-compatible, but sudo itself
      # is scoped above. Note sops env file is root-only; readable via
      # sops-nix ownership settings below.
    };
  };

  # --- reverse proxy -------------------------------------------------------
  services.nginx.virtualHosts."ci.nemesis.home.arpa" = {
    locations."/" = {
      proxyPass = "http://${serverHttpAddr}";
      proxyWebsockets = true;
      extraConfig = ''
        client_max_body_size 1G;
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [8003];
}
