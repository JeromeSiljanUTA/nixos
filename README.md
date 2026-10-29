# NixOS Config

## Hosts
- NEMESIS — server
- MIRAGE — custom router
- STARSCREAM — laptop
- BREAKDOWN — mini pc

## Rebuild
```sh
make          # nixos-rebuild switch on current host
make build    # build only
make test     # activate temporarily
make boot     # activate on next boot
make update   # nix flake update
```

Manual: `sudo nixos-rebuild switch --flake .#HOSTNAME`

## Layout
- `flake.nix` — host definitions (`nixosConfigurations`), inputs
- `hosts/<HOST>/` — per-host `configuration.nix` + hardware config
- `home/` — home-manager config; `home/hosts/` for host overrides
- `common/` — shared modules (desktop/sway, hardware, utils, ci)
- `DESIGN.md` — design decisions (CI, DNS, secrets)
- `.woodpecker.yml` — CI pipeline (push to master → rebuild nemesis)
- `hosts/NEMESIS/secrets.yaml` — sops-encrypted secrets

## CI
Woodpecker on nemesis rebuilds it on push to `master`. See `DESIGN.md`.

## Secrets
sops-nix (age). One policy file (`.sops.yaml`) + one ciphertext file per host
(`hosts/<HOST>/secrets.yaml`). Each host decrypts with its own
`/var/lib/sops-nix/age-key.txt`; the recovery key is `.secrets/admin-age-key.txt`
(gitignored).

Edit a host's secrets:
```sh
SOPS_AGE_KEY_FILE=.secrets/admin-age-key.txt sops hosts/NEMESIS/secrets.yaml
```

Adding a host: see the header of `.sops.yaml` and `DESIGN.md`.
