{
  description = "Home Manager configuration.";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      mkHome = { system, modules }: home-manager.lib.homeManagerConfiguration
      {
        pkgs = import nixpkgs { inherit system; };
        modules = modules ++ [
          ./home.nix
        ];
      };
    in {
      homeConfigurations = {
        darwin-intel = mkHome {
          system = "x86_64-darwin";
          modules = [];
        };
        linux-x86 = mkHome {
          system = "x86_64-linux";
          modules = [];
        };
        osx-intel = mkHome {
          # this is a test only
          system = "x86_64-darwin";
          modules = [
            ./hosts/osx.nix
          ];
        };
      };
    };
}
