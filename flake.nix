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

    # User's Neovim configuration (Kickstart-based with custom plugins)
    dotfiles-nvim = {
      url = "github:gschwim/dotfiles.nvim";
      flake = false;
    };

    # Official xAI Grok Build CLI (TUI coding agent) - maintained binary wrapper
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs = { self, nixpkgs-25-11, nixpkgs-26-05-darwin, home-manager-25-11, home-manager-26-05, dotfiles-nvim, llm-agents, ... }@inputs:
    let
      mkHome = { nixpkgs', home-manager', system, username, modules ? [] }:
        home-manager'.lib.homeManagerConfiguration {
          pkgs = import nixpkgs' {
            inherit system;
            # Allow unfree packages (e.g. Dropbox, some fonts, etc.).
            # This makes standalone `home-manager switch --flake` work
            # without needing NIXPKGS_ALLOW_UNFREE=1 --impure every time.
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit username;
            inherit dotfiles-nvim;
            inherit llm-agents;
          };
          modules = modules ++ [
            ./home.nix
          ];
        };
    in {
      # Project devShells (Poetry-first, Rust, etc.).
      # Defined in devshells/ (one file per shell + thin composer) per the approved plan.
      # Daily global Python lives in the CLI Home Manager profile, not here.
      devShells = import ./devshells {
        inherit nixpkgs-25-11 nixpkgs-26-05-darwin;
      };

      homeConfigurations = {
        # Linux pinned to 25.11 stable (no unstable)
        linux-x86 = mkHome {
          nixpkgs' = nixpkgs-25-11;
          home-manager' = home-manager-25-11;
          system = "x86_64-linux";
          username = "schwim";
          modules = [
            ./targets/linux.nix
          ];
        };

        # Linux with desktop/GUI apps (use this when you have GNOME, KDE, etc.)
        linux-x86-desktop = mkHome {
          nixpkgs' = nixpkgs-25-11;
          home-manager' = home-manager-25-11;
          system = "x86_64-linux";
          username = "schwim";
          modules = [
            ./targets/linux-desktop.nix
          ];
        };

        # Real machine: pleiades (imports linux-desktop target + host-specific overrides)
        pleiades = mkHome {
          nixpkgs' = nixpkgs-25-11;
          home-manager' = home-manager-25-11;
          system = "x86_64-linux";
          username = "schwim";
          modules = [
            ./hosts/pleiades.nix
          ];
        };

        # Intel macOS pinned to last supported release (26.05)
        darwin-intel = mkHome {
          nixpkgs' = nixpkgs-26-05-darwin;
          home-manager' = home-manager-26-05;
          system = "x86_64-darwin";
          username = "schwim";
          modules = [];
        };

        osx-intel = mkHome {
          nixpkgs' = nixpkgs-26-05-darwin;
          home-manager' = home-manager-26-05;
          system = "x86_64-darwin";
          username = "schwim";
          modules = [
            ./targets/osx.nix
          ];
        };
      };
    };
}
