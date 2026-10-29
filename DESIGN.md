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

*Layout — one policy, many files:*
- `.sops.yaml` — policy only, contains NO secrets. Lists age public keys and maps
  `hosts/<HOST>/secrets.yaml` → allowed recipients. Read only by the `sops` CLI;
  NixOS never reads it.
- `hosts/<HOST>/secrets.yaml` — ciphertext for one host, paired with
  `sops.defaultSopsFile` in that host's `configuration.nix`.
- `.secrets/admin-age-key.txt` — recovery private key (gitignored, NOT committed).
- `/var/lib/sops-nix/age-key.txt` — that host's private key, generated on the host
  and never committed.

*Adding a host (e.g. BREAKDOWN):*
1. On the host: `sudo nix shell nixpkgs#age -c age-keygen -o /var/lib/sops-nix/age-key.txt`
   (the private key never leaves the host; only its public key is published).
2. Add the public key as `&hostname` in `.sops.yaml` and a `creation_rule` for
   its `secrets.yaml`.
3. Add `sops-nix.nixosModules.sops` and a `sops { ... }` block to the host.
4. Create/edit the file with the admin key:
   `SOPS_AGE_KEY_FILE=.secrets/admin-age-key.txt sops hosts/<HOST>/secrets.yaml`
   (or `sops updatekeys` after adding a recipient).

*Existing hosts:*
- NEMESIS secrets: `woodpecker_agent_secret`, `woodpecker_gitea_client_id`,
  `woodpecker_gitea_client_secret`, `woodpecker_webhook_secret`,
  `woodpecker_gitea_token` (shipped via `sops.templates`).
- BREAKDOWN secrets: none yet — sops is wired up and ready for future secrets.

## DNS / networking

- dnsmasq on MIRAGE serves `home.arpa`; DHCP hands out mirage as resolver.
- MIRAGE firewall opens :53 on LAN only (`enp2s0`).
- **Wildcard:** `*.nemesis.home.arpa` → `192.168.10.10` (dnsmasq `address=` matches
  subdomains). Covers `git.`, `ci.`, and existing service vhosts.
- **Known gap:** `home.arpa` does not resolve over netbird from other networks.
  Fix belongs in netbird's DNS config (dashboard, not flake) + serving DNS on `wt0`.
  Tracked as a follow-up; not part of CI work.
