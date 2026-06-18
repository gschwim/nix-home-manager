{ config, pkgs, ... }:
{
  imports = [
    ../modules/desktop/common.nix
    ../modules/desktop/darwin.nix
  ];

  # macOS-specific desktop extras can go here if needed
  home.packages = with pkgs; [
    # Cross-platform desktop editor
    vscodium

    # placeholder was here
    # hello
  ];
}
