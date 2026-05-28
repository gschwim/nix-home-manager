{ config, pkgs, ... }:
{
  # Ghostty terminal configuration
  # Managed via Home Manager for consistency across macOS and Linux desktops.
  #
  # Theme: One Dark (as requested). Ghostty has good built-in One Dark support.
  # Feel free to tweak fonts/padding to match your Wezterm setup.

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

      # macOS-specific niceties
      macos-titlebar-style = "hidden"
      macos-option-as-alt = true

      # Linux/Wayland hints (harmless on macOS)
      linux-cgroup = "single-instance"

      # Keybindings
      # Keep most things default so your tmux (Ctrl-a) muscle memory works.
      # Example: make Cmd/Ctrl+, open config (macOS/Linux friendly)
      keybind = cmd+comma=reload_config
      keybind = ctrl+comma=reload_config

      # Misc quality of life
      confirm-close-surface = false
      window-save-state = "always"
    '';
  };
}
