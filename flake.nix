{
  description = "BREAKDOWN NixOS Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ad Blocking
    stevenblack-hosts = {
      url = "github:StevenBlack/hosts";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nur,
    stevenblack-hosts,
    sops-nix,
  }: {
    nixosConfigurations.BREAKDOWN = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ({...}: {
          nixpkgs.overlays = [
            nur.overlays.default
          ];
        })
        ./hosts/BREAKDOWN/configuration.nix

        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.jerome =
            import ./home/jerome.nix;
        }
      ];
    };

    nixosConfigurations.STARSCREAM = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ({...}: {
          nixpkgs.overlays = [
            nur.overlays.default
          ];
        })
        ./hosts/STARSCREAM/configuration.nix

        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.jerome = {
            imports = [
              ./home/jerome.nix
              ./home/hosts/STARSCREAM.nix
            ];
          };
        }
      ];
    };

    nixosConfigurations.MEGATRON = nixpkgs.lib.nixosSystem {
      modules = [
        ({...}: {
          nixpkgs.overlays = [
            nur.overlays.default
          ];
        })
        ./hosts/MEGATRON/configuration.nix

        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.jerome =
            import ./home/jerome.nix;
        }
      ];
    };

    nixosConfigurations.NEMESIS = nixpkgs.lib.nixosSystem {
      modules = [
        ({...}: {
          nixpkgs.overlays = [
            nur.overlays.default
          ];
        })
        ./hosts/NEMESIS/configuration.nix
        sops-nix.nixosModules.sops

        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.jerome =
            import ./home/jerome.nix;
        }
      ];
    };

    nixosConfigurations.MIRAGE = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit stevenblack-hosts;
      };

      modules = [
        ({...}: {
          nixpkgs.overlays = [
            nur.overlays.default
          ];
        })
        ./hosts/MIRAGE/configuration.nix

        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.jerome =
            import ./home/jerome.nix;
        }
      ];
    };
  };
}
