{ pkgs, ... }:
{
  # Common desktop/GUI packages that make sense on both macOS and Linux
  # when a graphical environment is available.
  #
  # Goal: Easy to add apps you like (e.g. for networking, system engineering,
  # note-taking, etc.) and have them available.
  # Prefer whatever the current desktop environment likes (GNOME, KDE, etc.).
  #
  # Note: Some packages in the desktop modules may be unfree.
  # Unfree packages are allowed by default in this flake's homeConfigurations.
  # If you import these modules elsewhere, you may need to enable them yourself.
  home.packages = with pkgs; [
    # Password management
    keepassxc

    # Communication / Messaging
    signal-desktop

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

    # Ghostty package is Linux-only in nixpkgs.
    # macOS users should install it via the official app/Homebrew; we still manage the config.
  ];

  # Manage Wezterm config declaratively on desktop profiles
  # (points to the wezterm.lua at the root of this repo)
  xdg.configFile."wezterm/wezterm.lua" = {
    source = ../../wezterm.lua;
  };
}
