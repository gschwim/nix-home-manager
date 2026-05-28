# Hosts

This directory is for **real machine-specific configurations**.

Each file here represents an actual computer (e.g. `pleiades.nix`, `work-laptop.nix`, `nas.nix`).

## How it works

A host file typically does two things:

1. Imports one or more **targets** from `../targets/` (these provide the base profile: headless Linux, Linux desktop, macOS, etc.).
2. Adds machine-specific overrides (extra packages, hardware-specific settings, secrets, user-specific tweaks, etc.).

### Example: `pleiades.nix`

```nix
# hosts/pleiades.nix
#
# Configuration for the "pleiades" machine.
# This is a real host that composes a target profile + machine-specific overrides.

{ config, pkgs, ... }:

{
  imports = [
    # Brings in the full Linux desktop target profile and everything it includes:
    #   - targets/linux.nix          (base Linux CLI + Linux-only tools)
    #   - modules/desktop/common.nix (cross-platform desktop apps)
    #   - modules/desktop/linux.nix  (Linux-specific desktop packages + Ghostty)
    ../targets/linux-desktop.nix
  ];

  # ------------------------------------------------------------
  # Host-specific overrides for pleiades only
  # ------------------------------------------------------------
  home.packages = with pkgs; [
    # Creative / audio production tools (only needed on this machine)
    blender
    reaper     # Note: unfree, allowed via the flake's mkHome config

    # Add anything else that should only exist on pleiades
  ];

  # GUI apps (blender, reaper, etc.) are handled for visibility in the
  # desktop launcher via modules/desktop/linux.nix. See pleiades.nix for notes
  # on NixOS vs non-NixOS behavior.
}
```

Then wire it up in `flake.nix`:

```nix
pleiades = mkHome {
  nixpkgs' = nixpkgs-25-11;
  home-manager' = home-manager-25-11;
  system = "x86_64-linux";
  username = "schwim";
  modules = [
    ./hosts/pleiades.nix
  ];
};
```

## Current State

This directory now contains a real example host:

- `pleiades.nix` — a full host that imports the `linux-desktop` target and adds machine-specific packages (blender, reaper, etc.). GUI apps get special desktop integration handling so they appear in GNOME/etc. launchers (see the file for NixOS vs portable notes).

You can build/switch it with:

```bash
home-manager switch --flake .#pleiades
```

Targets (reusable profiles) live in `../targets/`.
