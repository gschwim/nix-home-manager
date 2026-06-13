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
      # The homectl script content.
      # This is inlined as a plain string so that `builtins.readFile ./bin/homectl`
      # (and the associated flake source-tree snapshot problems) are never involved
      # when evaluating homeConfigurations, packages, or the activation data.
      #
      # Why: Home Manager's checkFilesChanged + darwin/fonts onChange etc. can
      # materialize additional `*-source` trees of the config while building
      # the home-manager-generation drv. Any relative path read at flake eval
      # time for a file that isn't committed can produce the exact error the
      # user was seeing:
      #   "opening file '/nix/store/...-source/bin/homectl': No such file or directory"
      #
      # bin/homectl on disk remains the convenient copy for direct execution
      # (`./bin/homectl info`, testing logic changes quickly, etc.). When you
      # modify the behavior, keep the string here and the file in bin/ in sync.
      homectlScript = ''
        #!/usr/bin/env bash
        # homectl - NixOS/Darwin-aware Home Manager deployment helper
        # See plan.md for design. Uses NIX_HOME_MANAGER_CONFIGS_DIR and /etc/nixos-host-info (when present).
        #
        # This is the packaged version (inlined in flake.nix).
        # The file bin/homectl is the direct-execution / development copy — keep them roughly in sync.
        set -euo pipefail

        print_usage() {
          cat <<'EOF'
Usage: homectl {switch|info|generations|target|pull} [args...]

  switch [...]   Deploy latest from the home-manager flake (NIX_HOME_MANAGER_CONFIGS_DIR) using auto-detected target
                 (passes extra args to home-manager switch)
  info           Show current/detected flake dir, target, host hints, last switched
  generations    List generations (wraps home-manager generations)
  target         Print just the auto-detected target (or error + list)
  pull           git pull origin master in the nix-home-manager repo (NIX_HOME_MANAGER_CONFIGS_DIR)

Detects using /etc/nixos-host-info (if present) + hostname + uname.
Highest priority: explicit flake_target (or FLAKE_TARGET) from host-info if it matches a target.
Then exact hostname match in homeConfigurations.
Falls back to desktop/role + OS logic (linux-x86-desktop / linux-x86).
On darwin we now default to osx-intel (desktop apps) for typical laptops;
darwin-intel (minimal) is legacy and only selected via explicit match or FLAKE_TARGET.
EOF
        }

        FLAKE_DIR="''${NIX_HOME_MANAGER_CONFIGS_DIR:-$HOME/src/nix-home-manager}"

        if [[ ! -d "$FLAKE_DIR" || ! -f "$FLAKE_DIR/flake.nix" ]]; then
          echo "homectl: cannot find home-manager flake dir at $FLAKE_DIR (set NIX_HOME_MANAGER_CONFIGS_DIR)" >&2
          exit 1
        fi

        # Parse host info file if present (KEY=VALUE lines). Allow override via
        # HOST_INFO_FILE for testing/advanced use; defaults to the /etc location
        # produced by nixos-configs (or equivalent on standalone Darwin).
        HOST_INFO_FILE="''${HOST_INFO_FILE:-/etc/nixos-host-info}"
        hostname=""
        desktop_environment="none"
        role=""
        flake_target=""
        if [[ -f "$HOST_INFO_FILE" ]]; then
          while IFS='=' read -r key value || [[ -n "$key" ]]; do
            key="''${key// /}"
            key="''${key,,}"  # lowercase for case-insensitive matching (nixos-configs side often uses UPPER_SNAKE_CASE)
            value="''${value// /}"
            value="''${value//\"/}"  # strip quotes if any
            case "$key" in
              hostname) hostname="$value" ;;
              desktop_environment|desktopenvironment) desktop_environment="$value" ;;
              role) role="$value" ;;
              flake_target|flaketarget) flake_target="$value" ;;
            esac
          done < "$HOST_INFO_FILE"
        fi

        # Fallback hostname
        if [[ -z "$hostname" ]]; then
          hostname="$(hostname -s 2>/dev/null || echo unknown)"
        fi

        is_darwin=false
        if [[ "$(uname -s)" == "Darwin" ]]; then
          is_darwin=true
        fi

        target=""

        has_target() {
          local t="$1"
          nix eval --json "$FLAKE_DIR#homeConfigurations" \
            --apply "attrs: builtins.hasAttr \"$t\" attrs" \
            --no-update-lock-file 2>/dev/null | grep -q true
        }

        list_targets() {
          nix eval --json "$FLAKE_DIR#homeConfigurations" \
            --apply 'builtins.attrNames' \
            --no-update-lock-file 2>/dev/null | tr -d '[]"' | tr ',' '\n' | sed 's/ //g' | sort
        }

        # Explicit FLAKE_TARGET (or flake_target) from /etc/nixos-host-info takes highest priority.
        # This allows the nixos-configs (or equivalent) side to declare the exact homeConfiguration
        # attr to use for this machine.
        if [[ -n "$flake_target" ]] && has_target "$flake_target"; then
          target="$flake_target"
        # 1. Hostname match (cross platform, most specific)
        elif has_target "$hostname"; then
          target="$hostname"
        elif $is_darwin; then
          # On darwin we default to osx-intel (the profile that pulls in desktop
          # apps via targets/osx.nix: obsidian, signal-desktop, vscodium, wezterm,
          # etc.). CLI-only macs are extremely rare ("who has a CLI-only mac??"),
          # so darwin-intel (the bare modules=[]) is now considered legacy/minimal.
          # If you really need the minimal one, use an explicit hostname match
          # in homeConfigurations or set FLAKE_TARGET=darwin-intel in
          # /etc/nixos-host-info. Hostname match above always takes precedence.
          target="osx-intel"
          # (We no longer look at desktop_environment for the darwin decision
          # during auto-detection; it was only there to choose between the two
          # and we're deprecating the minimal path for typical laptops.)
        elif [[ "$desktop_environment" != "none" ]]; then
          target="linux-x86-desktop"
        elif [[ "$role" == "server" ]]; then
          target="linux-x86"
        else
          target=""
        fi

        # State for "current implemented"
        STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/homectl"
        STATE_TARGET="$STATE_DIR/last-target"

        if [[ $# -eq 0 ]]; then
          print_usage
          exit 0
        fi

        cmd="$1"
        shift

        case "$cmd" in
          switch)
            if [[ -z "$target" ]]; then
              echo "homectl: no matching home-manager target found" >&2
              echo "  hostname=$hostname" >&2
              echo "  flake_target=''${flake_target:-}" >&2
              echo "  desktop_environment=$desktop_environment" >&2
              echo "  role=$role" >&2
              echo "  os=$(uname -s)" >&2
              echo "  flake=$FLAKE_DIR" >&2
              echo "Available targets:" >&2
              list_targets >&2
              exit 1
            fi
            echo "homectl: using target '$target' (from flake_target / hostname / role/desktop + os logic)"
            mkdir -p "$STATE_DIR"
            echo "$target" > "$STATE_TARGET"
            exec home-manager switch --flake "$FLAKE_DIR#$target" "$@"
            ;;
          info)
            echo "flake_dir: $FLAKE_DIR"
            echo "detected_target: ''${target:-<none>}"
            echo "hostname: $hostname"
            echo "flake_target: ''${flake_target:-}"
            echo "desktop_environment: $desktop_environment"
            echo "role: $role"
            echo "os: $(uname -s)"
            if [[ -f "$HOST_INFO_FILE" ]]; then
              echo "host_info:"
              cat "$HOST_INFO_FILE"
            fi
            if [[ -f "$STATE_TARGET" ]]; then
              echo "last_switched_target: $(cat "$STATE_TARGET")"
            fi
            ;;
          generations)
            exec home-manager generations "$@"
            ;;
          target)
            if [[ -z "$target" ]]; then
              echo "homectl: no target matched (see 'homectl info')" >&2
              echo "Available targets:"
              list_targets
              exit 1
            fi
            echo "$target"
            ;;
          pull)
            echo "homectl: git pull origin master in ''${FLAKE_DIR}"
            (cd "''${FLAKE_DIR}" && git pull origin master "$@")
            ;;
          *)
            echo "homectl: unknown command '$cmd'" >&2
            print_usage >&2
            exit 1
            ;;
        esac
      '';

      # homectl packages (defined early so we can pass to home configs for PATH installation)
      homectlFor = system:
        let
          p = if system == "x86_64-linux"
              then import nixpkgs-25-11 { inherit system; config.allowUnfree = true; }
              else import nixpkgs-26-05-darwin { inherit system; config.allowUnfree = true; };
        in
          p.writeShellScriptBin "homectl" homectlScript;

      mkHome = { nixpkgs', home-manager', system, username, modules ? [] }:
        home-manager'.lib.homeManagerConfiguration {
          pkgs = import nixpkgs' {
            inherit system;
            # Allow unfree packages (e.g. Dropbox, some fonts, etc.).
            # This makes standalone `home-manager switch --flake` work
            # without needing NIXPKGS_ALLOW_UNFREE=1 --impure every time.
            config = {
              allowUnfree = true;
              # Allow packages marked broken in the final x86_64-darwin nixpkgs
              # snapshot (e.g. arrow-cpp transitive dep pulled by pyproj/scipy/xarray
              # etc. when including modern scientific stacks like MetPy + Siphon in
              # the daily global Python).
              allowBroken = true;
            };
          };
          extraSpecialArgs = {
            inherit username;
            inherit dotfiles-nvim;
            inherit llm-agents;
            homectl = homectlFor system;
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
        # NOTE: darwin-intel is the bare/minimal profile (modules = []).
        # It is now considered legacy. Typical mac laptops should use osx-intel
        # (which imports targets/osx.nix and therefore gets desktop apps like
        # obsidian, signal-desktop, vscodium, etc.).
        # darwin-intel is kept only for explicit use via hostname match or
        # FLAKE_TARGET=darwin-intel. CLI-only macs are rare.
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

      # homectl - the deployment helper (switch/info/generations + auto target selection from /etc/nixos-host-info + hostname)
      # Exposed so `nix run .#homectl switch` (or from remote) works, and installable into profile for PATH.
      # The script body is inlined above (homectlScript) precisely so that no
      # `builtins.readFile ./bin/...` or source path from the flake root ever
      # participates in home-manager-generation / activation data evaluation.
      packages = {
        x86_64-linux.homectl = homectlFor "x86_64-linux";
        x86_64-darwin.homectl = homectlFor "x86_64-darwin";
      };

      apps = {
        x86_64-linux.homectl = {
          type = "app";
          program = self.packages.x86_64-linux.homectl + "/bin/homectl";
        };
        x86_64-darwin.homectl = {
          type = "app";
          program = self.packages.x86_64-darwin.homectl + "/bin/homectl";
        };
      };
    };
}
