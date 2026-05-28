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
}
