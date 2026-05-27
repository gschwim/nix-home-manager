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
  #     modules = [ ./hosts/linux.nix ];
  #   };

  home.packages = with pkgs; [
    # Add common Linux CLI niceties here as needed.
    # Most heavy lifting is already in modules/cli/.
  ];
}
