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
sops-nix (age). Host key at `/var/lib/sops-nix/age-key.txt`.
Edit: `SOPS_AGE_KEY_FILE=.secrets/admin-age-key.txt sops hosts/NEMESIS/secrets.yaml`
Setup steps: see `DESIGN.md`.
