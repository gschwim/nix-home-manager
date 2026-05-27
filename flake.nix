{
  description = "Home Manager configuration.";

  inputs = {
    # Stable 25.11 for Linux (and any future non-Intel-darwin systems)
    nixpkgs-25-11.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Final supported release for x86_64-darwin (Intel Macs).
    # 26.05 is the last nixpkgs release with x86_64-darwin support.
    nixpkgs-26-05-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    home-manager-25-11 = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-25-11";
    };

    # Home Manager release branch matching the pinned 26.05-darwin nixpkgs
    home-manager-26-05 = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-26-05-darwin";
    };
  };

  outputs = { self, nixpkgs-25-11, nixpkgs-26-05-darwin, home-manager-25-11, home-manager-26-05, ... }:
    let
      mkHome = { nixpkgs', home-manager', system, modules }:
        home-manager'.lib.homeManagerConfiguration {
          pkgs = import nixpkgs' { inherit system; };
          modules = modules ++ [
            ./home.nix
          ];
        };
    in {
      homeConfigurations = {
        # Linux pinned to 25.11 stable (no unstable)
        linux-x86 = mkHome {
          nixpkgs' = nixpkgs-25-11;
          home-manager' = home-manager-25-11;
          system = "x86_64-linux";
          modules = [];
        };

        # Intel macOS pinned to last supported release (26.05)
        darwin-intel = mkHome {
          nixpkgs' = nixpkgs-26-05-darwin;
          home-manager' = home-manager-26-05;
          system = "x86_64-darwin";
          modules = [];
        };

        osx-intel = mkHome {
          nixpkgs' = nixpkgs-26-05-darwin;
          home-manager' = home-manager-26-05;
          system = "x86_64-darwin";
          modules = [
            ./hosts/osx.nix
          ];
        };
      };
    };
}
