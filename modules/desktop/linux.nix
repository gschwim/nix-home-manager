{ pkgs, ... }:
{
  # Linux-specific desktop configuration.
  # This can include things that behave differently on Linux desktops
  # (fontconfig tweaks, XDG portals, etc.) when needed.
  #
  # For most apps, putting them in common.nix is sufficient.
  home.packages = with pkgs; [
    # Linux-desktop only packages can go here
  ];
}
