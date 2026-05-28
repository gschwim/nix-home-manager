{ pkgs, ... }:
{
  # macOS-specific desktop configuration.
  # Things that only make sense on Darwin when using a GUI.
  home.packages = with pkgs; [
    # macOS desktop-only packages can go here
  ];
}
