{ config, pkgs, ... }:
{
  # Linux desktop host configuration.
  # Use this when you have a graphical environment (GNOME, KDE, etc.).
  #
  # This gives you CLI tools + desktop/GUI apps.
  # Note: We deliberately do NOT import ./linux.nix here to avoid pulling
  # CLI-only versions of tools that have GUI counterparts (e.g. mtr vs mtr-gui).
  imports = [
    ../modules/desktop/common.nix
    ../modules/desktop/linux.nix
  ];

  home.packages = with pkgs; [
    # Linux-specific networking / system tools that are also useful on desktop
    ethtool
    iproute2   # provides the `ss` command

    # Cross-platform desktop editor
    vscodium
  ];
}
