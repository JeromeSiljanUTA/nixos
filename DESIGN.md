# Design Decisions

## Hosts
- NEMESIS — server (docker: gitea, media\*, etc; nginx reverse proxy; netbird)
- MIRAGE — custom router (dnsmasq, nftables NAT, DHCP)
- STARSCREAM — laptop
- BREAKDOWN — mini pc
- MEGATRON — (legacy/other)

Rebuilds detect hostname automatically via `make`.

## CI/CD (Woodpecker on NEMESIS)

**Goal:** push to `master` of `jerome/nixos` → nemesis rebuilds itself.

**Choices & rationale:**
- **Woodpecker CI**, native NixOS services (`services.woodpecker-server` / `-agents`), not docker.
  - A docker agent cannot cleanly drive host `nixos-rebuild switch` (needs host nix store,
    systemd activation). Native service keeps config in the flake.
- **External CI + Gitea webhook** instead of Gitea Actions, so switching git servers
  later only requires re-pointing the webhook.
- **HTTP clone URL** (`http://git.nemesis.home.arpa/jerome/nixos`), token-based, repo scope.
  No SSH key/password access to the server.
  - URL comes from Gitea (set when enabling the repo in Woodpecker), so CI files stay portable.
- **Agent runs as dedicated `woodpecker` user** with sudoers scoped to `nixos-rebuild` only.
- **Port 8003** behind existing nginx; vhost `ci.nemesis.home.arpa`.
- **No `nix flake check`** in pipeline — go straight to `nixos-rebuild switch`; fail = fail.

**Agent is custom, not `services.woodpecker-agents`.** The stock agent runs as
`DynamicUser` with `ProtectSystem=strict`, `PrivateUsers`, `NoNewPrivileges`.
That sandbox cannot run `nixos-rebuild switch` (needs root + writable /nix, /etc,
systemd) and exposes no user/group option for sudoers. So the agent is a custom
systemd unit running `woodpecker-agent` (local backend) as the stable
`woodpecker` user. The **server** uses the stock module.

**Sudo:** `woodpecker` may run only `nixos-rebuild switch --flake *`, NOPASSWD.

**Secrets: sops-nix** (age). Ciphertext is safe to commit publicly.
- Admin/recovery key: `.secrets/admin-age-key.txt` (gitignored, NOT committed).
- Host key: `/var/lib/sops-nix/age-key.txt` on nemesis (one-time, see below).
- Secret names in `hosts/NEMESIS/secrets.yaml`: `woodpecker_agent_secret`,
  `woodpecker_gitea_client_id`, `woodpecker_gitea_client_secret`,
  `woodpecker_webhook_secret`, `woodpecker_gitea_token`.
- Values are shipped to services via `sops.templates` (secret file → env file).

## DNS / networking

- dnsmasq on MIRAGE serves `home.arpa`; DHCP hands out mirage as resolver.
- MIRAGE firewall opens :53 on LAN only (`enp2s0`).
- **Wildcard:** `*.nemesis.home.arpa` → `192.168.10.10` (dnsmasq `address=` matches
  subdomains). Covers `git.`, `ci.`, and existing service vhosts.
- **Known gap:** `home.arpa` does not resolve over netbird from other networks.
  Fix belongs in netbird's DNS config (dashboard, not flake) + serving DNS on `wt0`.
  Tracked as a follow-up; not part of CI work.
