{ config, pkgs, ... }:
{
  # Base Linux host configuration.
  # Shared across Ubuntu, NixOS, and other Linux distributions.
  #
  # Put Linux-specific packages or settings here (e.g. things that behave
  # differently on Linux vs macOS, or distro-agnostic CLI tools).
  #
  # Example usage in flake.nix:
  #   linux-x86 = mkHome {
  #     ...
  #     modules = [ ./targets/linux.nix ];
  #   };

  home.packages = with pkgs; [
    # Linux-only networking / system tools (not available or different on macOS)
    ethtool
    iproute2   # provides the `ss` command

    # CLI mtr (the GUI version is provided by mtr-gui in desktop profiles)
    mtr

    # Add other common Linux CLI niceties here as needed.
    # Most heavy lifting (cross-platform) is already in modules/cli/.
  ];
}
