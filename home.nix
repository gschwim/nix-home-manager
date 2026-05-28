{ config, pkgs, username, dotfiles-nvim, ... }:

{
  imports = [
    ./modules/cli/cli.nix
  ];

  # Username is supplied by the flake (see mkHome in flake.nix).
  # This makes the configuration portable across users and machines.
  home.username = username;

  # Home directory is derived from username + OS. This cleanly handles
  # the path differences between macOS (/Users/<user>) and Linux (/home/<user>)
  # without hardcoding any specific username.
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then
      "/Users/${username}"
    else if pkgs.stdenv.isLinux then
      "/home/${username}"
    else
      throw "Unsupported OS: only Darwin (macOS) and Linux are supported";

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  #
  # Bumped to 25.11 to match the nixpkgs-25-11 pin used for Linux configurations.
  home.stateVersion = "25.11";

  #
  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/<username>/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
    ZSH_AUTOSUGGEST_MANUAL_REBIND="True";
    SHELL = "${pkgs.zsh}/bin/zsh";
  };

  # Bring in the full Neovim configuration from the external dotfiles.nvim repo.
  # This makes the entire ~/.config/nvim directory managed by Home Manager/Nix.
  # The config (based on kickstart.nvim + lazy.nvim) will manage its own plugins.
  xdg.configFile."nvim" = {
    source = dotfiles-nvim;
    recursive = true;
    # Force overwrite so the full dotfiles.nvim config takes precedence
    # over any previously generated or manual files in ~/.config/nvim
    force = true;
  };
}
