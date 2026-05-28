{ pkgs, ... }:
{
  imports = [
    ./ghostty.nix
  ];

  # Common desktop/GUI packages that make sense on both macOS and Linux
  # when a graphical environment is available.
  #
  # Goal: Easy to add apps you like (e.g. for networking, system engineering,
  # note-taking, etc.) and have them available.
  # Prefer whatever the current desktop environment likes (GNOME, KDE, etc.).
  #
  # Note: Some packages (e.g. dropbox) are unfree and require
  # `nixpkgs.config.allowUnfree = true;` (or the predicate equivalent).
  home.packages = with pkgs; [
    # Password management
    keepassxc

    # Communication / Messaging
    signal-desktop

    # Cloud sync / storage
    dropbox

    # Networking & packet analysis
    wireshark
    termshark
    mtr-gui

    # Knowledge base / note-taking (great for runbooks, diagrams, etc.)
    obsidian

    # Editors
    vscodium

    # Terminals (your custom wezterm.lua config lives alongside this)
    wezterm

    # Ghostty - modern GPU terminal (with OneDark theme preference)
    ghostty
  ];
}
