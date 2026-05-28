{ pkgs, ... }:
{
  # Linux-specific desktop configuration.
  # This can include things that behave differently on Linux desktops
  # (fontconfig tweaks, XDG portals, etc.) when needed.
  #
  # For most apps, putting them in common.nix is sufficient.
  home.packages = with pkgs; [
    # Linux-desktop only packages
    dropbox   # Not available on Darwin. Requires unfree (allowed in this flake).
    ghostty   # GPU-accelerated terminal (not yet available for Darwin in nixpkgs)
  ];

  # Desktop integration for GUI apps installed via Home Manager.
  #
  # Problem: On Linux (both NixOS with standalone HM and non-NixOS distros like
  # Ubuntu/Mint), apps installed through `home.packages` (e.g. blender, reaper,
  # signal-desktop, etc.) often do not appear in the GNOME/Cinnamon/etc. app
  # launcher because their .desktop files live in ~/.nix-profile/share/applications,
  # which most desktop environments do not reliably scan.
  #
  # This block symlinks the .desktop files into ~/.local/share/applications and
  # updates the desktop database so they show up properly.
  #
  # This is a portable workaround that works on NixOS, Ubuntu, Mint, etc.
  #
  # Recommendation for pure NixOS machines:
  #   For large GUI apps you want to feel "native", prefer installing them in
  #   your system configuration.nix via `environment.systemPackages` instead.
  #   They will then integrate perfectly without any extra work.
  home.extraProfileCommands = ''
    DESKTOP_SRC="$HOME/.nix-profile/share/applications"
    DESKTOP_DST="$HOME/.local/share/applications"

    if [ -d "$DESKTOP_SRC" ]; then
      mkdir -p "$DESKTOP_DST"
      for desktop in "$DESKTOP_SRC/"*.desktop; do
        [ -f "$desktop" ] && ln -sf "$desktop" "$DESKTOP_DST/"
      done

      # Update desktop database (works on GNOME, Cinnamon, etc.)
      if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$DESKTOP_DST" || true
      fi

      # Also update icon cache if gtk-update-icon-cache is available
      if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -q -t -f "$HOME/.local/share/icons" || true
      fi
    fi
  '';

  # Ghostty configuration (Linux desktop only)
  xdg.configFile."ghostty/config" = {
    text = ''
      # Theme
      theme = "One Dark"

      # Fonts - matching your Wezterm preferences
      font-family = "Fantasque Sans Mono"
      font-family = "Caskaydia Cove Nerd Font"
      font-size = 14

      # Window appearance
      window-padding-x = 8
      window-padding-y = 8
      window-theme = "dark"

      # Shell integration (very useful with your zsh/tmux setup)
      shell-integration = "detect"

      # Explicitly use zsh as the default shell
      shell = "${pkgs.zsh}/bin/zsh"

      # macOS-specific niceties (harmless on Linux)
      macos-titlebar-style = "hidden"
      macos-option-as-alt = true

      # Linux/Wayland hints
      linux-cgroup = "single-instance"

      # Keybindings
      keybind = cmd+comma=reload_config
      keybind = ctrl+comma=reload_config

      # Misc quality of life
      confirm-close-surface = false
      window-save-state = "always"
    '';
  };
}
