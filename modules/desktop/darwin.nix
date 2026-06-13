{ pkgs, lib, ... }:
{
  # macOS-specific desktop configuration.
  # Things that only make sense on Darwin when using a GUI.
  home.packages = with pkgs; [
    # macOS desktop-only packages can go here
  ];

  # Symlink GUI apps (.app bundles) from the Home Manager profile into ~/Applications.
  #
  # Why this is needed:
  #   - Home Manager (and Nix on Darwin) installs GUI apps into the Nix store and
  #     the user profile (typically ~/.nix-profile/Applications/Obsidian.app etc.).
  #   - macOS Launchpad, Spotlight, Dock, and the "Applications" folder only reliably
  #     discover apps that are (symlinked) inside ~/Applications or /Applications.
  #   - Unlike on Linux (where we have the extraProfileCommands hack in linux.nix
  #     to make .desktop files visible), there is no equivalent automatic integration
  #     for Darwin .app bundles in the default Home Manager activation for all setups.
  #
  # Cleanup on removal:
  #   The script below first removes any previously-managed symlinks (those pointing
  #   into the Nix profile/store) before (re)creating only the ones that are currently
  #   present in the active profile. This means if you remove an app from your config
  #   and switch, the corresponding symlink in ~/Applications will be cleaned up.
  #
  # Automatic quarantine clearing (xattr):
  #   After (re)linking, we run `xattr -cr` on the apps. This is the equivalent of the
  #   manual `xattr -cr ~/Applications/Obsidian.app` you would otherwise have to run
  #   for apps that macOS marks as "damaged".
  #   Because this lives in a Home Manager activation, it runs automatically as part
  #   of `home-manager switch` — and therefore also as part of `homectl switch`.
  #
  # Result: apps declared in modules/desktop/common.nix (obsidian, signal-desktop,
  # vscodium, wezterm, etc.) will appear as symlinks in ~/Applications after a switch
  # and will not require manual xattr fiddling.
  #
  # Note: You may still need to run `killall Dock` (or log out/in) to refresh Launchpad
  # after the first switch that adds/removes apps.
  home.activation.copyDarwinApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    appsSrc="$HOME/.nix-profile/Applications"
    appsDst="$HOME/Applications"

    mkdir -p "$appsDst"

    # Remove any symlinks we previously managed (pointing into the Nix profile or store).
    # This cleans up apps that have been removed from the Home Manager configuration.
    find "$appsDst" -maxdepth 1 -type l \( -lname '*nix/store*' -o -lname '*nix-profile*' \) \
      -exec rm -f {} + 2>/dev/null || true

    # (Re)create symlinks for the apps that are currently in the active profile.
    if [ -d "$appsSrc" ]; then
      for app in "$appsSrc"/*.app; do
        if [ -d "$app" ]; then
          target="$appsDst/$(basename "$app")"
          ln -sfn "$app" "$target"
          # Clear macOS quarantine attribute so the app doesn't appear "damaged".
          # This makes the xattr step automatic as part of every switch (including
          # via homectl switch, which just invokes home-manager switch).
          xattr -cr "$target" 2>/dev/null || true
        fi
      done
    fi
  '';
}
