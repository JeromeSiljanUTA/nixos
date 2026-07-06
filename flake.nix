{
	description = "BREAKDOWN NixOS Config";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

		home-manager = {
			url = "github:nix-community/home-manager/release-26.05";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { self, nixpkgs, home-manager }: {
		nixosConfigurations.BREAKDOWN = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";

			modules = [
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
	};
}
