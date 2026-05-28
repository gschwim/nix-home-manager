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
