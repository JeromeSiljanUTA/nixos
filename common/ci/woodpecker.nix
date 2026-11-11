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
  # The rebuild restarts woodpecker-agent, which would kill this step if run
  # in-process. Run it as a detached transient unit in its own cgroup, then
  # poll its result so the pipeline reports success/failure accurately.
  systemctl = "${config.systemd.package}/bin/systemctl";
  journalctl = "${config.systemd.package}/bin/journalctl";
  rebuildWrapper = pkgs.writeShellScript "woodpecker-nixos-rebuild" ''
    set -eu
    # Nix refuses git/plain dirs it doesn't own; mark the checkout safe.
    export HOME=/var/lib/woodpecker
    export GIT_CONFIG_COUNT=1
    export GIT_CONFIG_KEY_0=safe.directory
    export GIT_CONFIG_VALUE_0='*'
    # Rebuild from the flake at the CURRENT working directory (the CI checkout).
    flake="$PWD#NEMESIS"
    unit="ci-nixos-rebuild-$RANDOM$$"

    ${config.systemd.package}/bin/systemd-run \
      --unit="$unit" --collect --no-block \
      --setenv=HOME=/var/lib/woodpecker \
      --setenv=GIT_CONFIG_COUNT=1 \
      --setenv=GIT_CONFIG_KEY_0=safe.directory \
      --setenv=GIT_CONFIG_VALUE_0='*' \
      ${config.system.path}/bin/nixos-rebuild switch --flake "$flake"

    # Poll until the unit is no longer active, then report its result.
    while ${systemctl} is-active --quiet "$unit"; do
      sleep 5
    done
    if ${systemctl} is-failed --quiet "$unit"; then
      ${journalctl} -u "$unit" -n 50 --no-pager >&2
      exit 1
    fi
    echo "rebuild unit $unit finished successfully"
  '';
  rebuildWrapperPath = "/run/woodpecker/rebuild";

  # Redeploy docker services via the shockwaves-lab Makefile. The Makefile is
  deployRepo = "/iacon/containers/shockwaves-lab";
  deployListPath = "/var/lib/woodpecker/deploy-services";
  makeBin = "${pkgs.gnumake}/bin/make";
  dockerComposePath = pkgs.writeScript "woodpecker-docker-deploy" ''
    #!${pkgs.bash}/bin/bash
    set -eu
    repo=${lib.escapeShellArg deployRepo}
    list=${lib.escapeShellArg deployListPath}

    [ -f "$list" ] || { echo "no deploy list at $list" >&2; exit 1; }
    [ -d "$repo/.git" ] || { echo "$repo is not a git clone" >&2; exit 1; }
    cd "$repo"

    # Only newline-separated, validated directory names are honoured.
    while IFS= read -r svc; do
      [ -n "$svc" ] || continue
      case "$svc" in
        *[!A-Za-z0-9._-]*|.*) echo "skipping invalid service: $svc" >&2; continue ;;
      esac
      [ -f "$repo/$svc/docker-compose.yml" ] || { echo "no compose for $svc" >&2; exit 1; }
      echo "==> redeploy $svc"
      # We are already root here; pass DOCKER so the Makefile does not nest sudo.
      ${makeBin} deploy SERVICE="$svc" DOCKER=${config.virtualisation.docker.package}/bin/docker
    done < "$list"
  '';
  dockerComposeWrapperPath = "/run/woodpecker/docker-deploy";

  # Force the F-Droid builder to ingest freshly uploaded APKs and rebuild the
  # repo index immediately, rather than waiting for its periodic timer.
  fdroidRebuild = pkgs.writeShellScript "woodpecker-fdroid-rebuild" ''
    #!${pkgs.bash}/bin/bash
    set -eu
    exec ${config.virtualisation.docker.package}/bin/docker \
      exec fdroid bash /updates-scripts/10-ingest-uploads.sh
  '';
  fdroidRebuildWrapperPath = "/run/woodpecker/fdroid-rebuild";
in {
  # Expose the wrappers as REAL root-owned files (not symlinks) at fixed
  # paths. sudo canonicalizes symlinks against the store before matching, which
  # would break the sudoers rule; a regular file avoids that.
  systemd.tmpfiles.rules = [
    "C+ ${rebuildWrapperPath} 0755 root root - ${rebuildWrapper}"
    "C+ ${dockerComposeWrapperPath} 0755 root root - ${dockerComposePath}"
    "C+ ${fdroidRebuildWrapperPath} 0755 root root - ${fdroidRebuild}"
    "d /iacon/containers 2775 jerome shockwaves -"
    "Z ${deployRepo} 2775 jerome shockwaves -"
    "f ${deployListPath} 0664 ${ciUser} shockwaves -"
  ];
  # --- scoped rebuild user -------------------------------------------------
  users.groups.shockwaves = {};
  users.users.${ciUser} = {
    isSystemUser = true;
    group = ciUser;
    extraGroups = ["shockwaves"];
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
        {
          # Redeploy via the Makefile. NO arguments: the wrapper reads the
          # service list from a fixed CI-owned file, so nothing
          # caller-controlled crosses the sudo boundary.
          command = dockerComposeWrapperPath;
          options = ["NOPASSWD"];
        }
        {
          # Force an F-Droid ingest + index rebuild. No arguments.
          command = fdroidRebuildWrapperPath;
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
      DEPLOY_GIT_TOKEN=${config.sops.placeholder.woodpecker_gitea_token}
      VECTOR_PRIME_KEYSTORE_JKS=${config.sops.placeholder.vector_prime_keystore_jks}
      VECTOR_PRIME_KEYSTORE_PASSWORD=${config.sops.placeholder.vector_prime_keystore_password}
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
    # Rendered sops templates are written by systemd-tmpfiles-resetup;
    # secrets are otherwise installed during activation. There is NO
    # sops-install-secrets.service unit on this system.
    after = ["network-online.target" "woodpecker-server.service" "systemd-tmpfiles-resetup.service"];
    wants = ["network-online.target" "woodpecker-server.service"];
    # The local backend shells out to these; they must be on PATH.
    # Note: sudo must be the setuid wrapper, NOT pkgs.sudo (store binaries
    # cannot be setuid). This is why pkgs.sudo is intentionally absent here.
    path = [
      # systemd appends /bin and /sbin to each entry, so point at the prefix.
      "/run/wrappers"
      pkgs.bash
      pkgs.coreutils
      pkgs.git
      pkgs.git-lfs
      pkgs.woodpecker-plugin-git
      config.nix.package
      pkgs.crane
    ];
    environment = {
      # Agent dials the server's gRPC port, not the HTTP UI port.
      WOODPECKER_SERVER = serverGrpcAddr;
      WOODPECKER_BACKEND = "local";
      WOODPECKER_MAX_WORKFLOWS = "1";
      # Avoid colliding with Gitea on :3000.
      WOODPECKER_HEALTHCHECK_ADDR = agentHealthAddr;
      HOME = "/var/lib/woodpecker";
      GIT_CONFIG_COUNT = "1";
      GIT_CONFIG_KEY_0 = "safe.directory";
      GIT_CONFIG_VALUE_0 = "*";
    };
    serviceConfig = {
      User = ciUser;
      Group = ciUser;
      UMask = "0002";
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
