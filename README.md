# nix-home-manager

Personal Home Manager configuration using flakes. Designed to work cleanly across:

- macOS (Intel)
- Ubuntu Linux
- NixOS

## Current State (as of 2026)

- **Linux**: Pinned to `nixpkgs-25.11` + matching `home-manager/release-25.11`
- **Intel macOS**: Pinned to the final supported release (`nixpkgs-26.05-darwin` + `home-manager/release-26.05`)
- Fully user-agnostic: no hard-coded usernames. The same config works for any user on any supported machine.
- Core shell environment lives in `modules/cli/` (zsh + starship + tmux + fzf + git+delta + eza + bat + direnv + neovim + etc.)

## Usage

### On macOS (Intel)

```bash
cd ~/src/nix-home-manager

# Daily driver (includes extras from targets/osx.nix)
home-manager switch --flake .#osx-intel

# Minimal version
home-manager switch --flake .#darwin-intel
```

### On Linux (Ubuntu or NixOS)

```bash
cd ~/src/nix-home-manager

home-manager switch --flake .#linux-x86
```

The configuration now works for **any username** without editing source files. When defining new machines, just pass the desired `username` in the flake.

## Repository Structure

```
flake.nix                 # Pins + homeConfigurations + mkHome helper
home.nix                  # Core settings (now receives username from the flake)
modules/cli/              # The actual configuration you care about
├── cli.nix
├── packages.nix
├── programs.nix
└── variables.nix         # Large git alias collection + starship config
targets/
├── linux.nix             # Base Linux target profile
├── linux-desktop.nix     # Linux + desktop environment target
└── osx.nix               # macOS target profile

hosts/
└── (real machine configs go here, e.g. pleiades.nix)
devshells/                # Legacy Python environments (see TODOs below)
```

## Making It Work for a Different User / Machine

Because everything is now parameterized:

1. In `flake.nix`, add or modify a `homeConfiguration` and supply the correct `username`.
2. Optionally import or extend a target from `targets/` (or a full host config from `hosts/`).
3. Run `home-manager switch --flake .#your-config`.

Example for a new Linux user "alice":

```nix
alice-laptop = mkHome {
  nixpkgs' = nixpkgs-25-11;
  home-manager' = home-manager-25-11;
  system = "x86_64-linux";
  username = "alice";
  modules = [ ./targets/linux.nix ];
};
```

## Default Shell

This configuration enables and heavily customizes Zsh for all profiles.

To make Zsh your actual default shell:

- **On NixOS** (recommended when using Home Manager as a module):  
  Set `users.users.<yourname>.shell = pkgs.zsh;` in your system configuration.

- **Standalone** (macOS, Ubuntu, or standalone on NixOS):  
  Run `chsh -s $(which zsh)` (or the full Nix store path).

We also set `SHELL` and configure Ghostty + Wezterm (on desktop profiles) to prefer Zsh.

## Deferred Work (TODOs)

- **Python / language devshells**: The old `devshells/` flake and the wrapper scripts in `packages.nix` are outdated and broken in places. Modernizing and consolidating them into the main flake is tracked as future work.
- **Bootstrap story**: The old `install` + `lib.sh` scripts are deprecated. A clean, modern way to bootstrap a brand new machine from scratch is a planned future improvement.
- **Pure Nix Neovim configuration (optional)**: The current Neovim setup sources the entire `dotfiles.nvim` repo via `xdg.configFile."nvim"`. A full conversion to declarative `programs.neovim` (plugins, treesitter grammars, etc.) is possible but would be significant effort because the config is built on lazy.nvim. This is tracked as an **optional low-priority future item**.
- **NixOS module integration**: Support using this configuration via Home Manager as a NixOS module (instead of standalone `home-manager switch`). This would allow managing system + user configuration together with a single `nixos-rebuild switch`.

The legacy scripts have deprecation headers and should not be used for new setups.

## Verification

After changes:

```bash
nix flake check
nix eval --json .#homeConfigurations --apply builtins.attrNames
```

## Notes

- `home.stateVersion` is set to `"25.11"` on the Linux side (matching the pin).
- The old `/home/schwim2` references and other machine-specific hardcoding have been removed.
- Most of the value is in the shared `modules/cli/` programs and aliases — those are intentionally left alone unless something is actually broken.

Contributions / extensions are welcome as long as they don't regress the multi-OS (macOS + Ubuntu + NixOS) and user-agnostic goals.
