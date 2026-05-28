{ config, pkgs, ... }:
{
  # Linux desktop host configuration.
  # Use this when you have a graphical environment (GNOME, KDE, etc.).
  #
  # This gives you CLI tools + desktop/GUI apps.
  imports = [
    ./linux.nix
    ../modules/desktop/common.nix
    ../modules/desktop/linux.nix
  ];
}
