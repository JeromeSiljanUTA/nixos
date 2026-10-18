HOST := $(shell hostname 2>/dev/null || cat /proc/sys/kernel/hostname)
FLAKE := .

.PHONY: switch build test boot update fmt

switch:
	sudo nixos-rebuild switch --flake $(FLAKE)#$(HOST)

build:
	sudo nixos-rebuild build --flake $(FLAKE)#$(HOST)

test:
	sudo nixos-rebuild test --flake $(FLAKE)#$(HOST)

boot:
	sudo nixos-rebuild boot --flake $(FLAKE)#$(HOST)

update:
	nix flake update

fmt:
	nix fmt
