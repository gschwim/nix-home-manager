{
  description = "Home Manager configuration for macOS with Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";  # Use unstable channel
    home-manager = {
      url = "github:nix-community/home-manager/master";  # Match your stateVersion
      inputs.nixpkgs.follows = "nixpkgs";  # Align nixpkgs versions
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      username = "schwim";  # Hardcoded as fallback, your home.nix uses builtins.getEnv "USER"
      mkHome = { system, configName }: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = system;
          config.allowUnfree = true;  # Optional: enable if you add unfree packages later
        };
        modules = [
          ./home.nix
          {
            # Optional: Override username and homeDirectory if env vars aren't set
            home = {
              username = username;
              homeDirectory = "/Users/${username}";
            };
          }
        ];
      };
    in {
      homeConfigurations = {
        "darwin-intel" = mkHome {
          system = "x86_64-darwin";
          configName = "darwin-intel";
        };
        "darwin-silicon" = mkHome {
          system = "aarch64-darwin";
          configName = "darwin-silicon";
        };
      };

      # Optional: Dev shell for managing the flake
      devShells = {
        "x86_64-darwin" = nixpkgs.legacyPackages."x86_64-darwin".mkShell {
          buildInputs = [ home-manager.packages."x86_64-darwin".home-manager ];
        };
        "aarch64-darwin" = nixpkgs.legacyPackages."aarch64-darwin".mkShell {
          buildInputs = [ home-manager.packages."aarch64-darwin".home-manager ];
        };
      };
    };
}

