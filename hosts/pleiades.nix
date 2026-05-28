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

  # NOTE on GUI apps (blender, reaper, etc.):
  #
  # These are installed via Home Manager so they work on both NixOS and
  # non-NixOS machines (Ubuntu, Mint, etc.).
  #
  # On Linux desktops, GUI apps installed through `home.packages` often do
  # not appear in the GNOME/Cinnamon/etc. launcher. We handle this automatically
  # via the logic in modules/desktop/linux.nix (it symlinks .desktop files into
  # ~/.local/share/applications and updates the database).
  #
  # If you are on a pure NixOS machine and want the absolute best integration
  # (no extra work, perfect icon/theme integration, etc.), consider moving
  # heavy GUI apps like these into your system configuration.nix under
  # `environment.systemPackages` instead.
}
