{ config, pkgs, username, dotfiles-nvim, homectl, ... }:

{
  imports = [
    ./modules/cli/cli.nix
    # Personal-only update checker (timer + script). Maintainer use only.
    # Forks: remove this line (and the whole modules/personal/ bits if desired).
    ./modules/personal/update-checker.nix
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

  # (personal update checker imported above in the main imports list)

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

  # Silence the post-switch message:
  #   "There are N unread and relevant news items.
  #    Read them by running the command "home-manager news"."
  #
  # This message comes from Home Manager's activation when using the standalone
  # `home-manager` CLI. It is mainly useful for people tracking the unstable
  # channel with the classic ~/.config/home-manager/home.nix setup.
  #
  # We use flakes + pinned home-manager releases (nixpkgs-25.11 + matching
  # home-manager/release-25.11 for Linux, 26.05-darwin for Intel macOS), so
  # the news are rarely relevant and the plain `home-manager news` command
  # doesn't work (it looks for a legacy config file and prints the error you saw).
  #
  # To view news for a specific flake target when you actually want them:
  #   nix run home-manager/release-25.11 -- news --flake .#linux-x86
  #   nix run home-manager/release-26.05 -- news --flake .#osx-intel
  #
  # Or after a switch you can try:
  #   home-manager news --flake .#linux-x86
  news.display = "silent";

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

    # Canonical locations of the two main source repositories.
    # Helper scripts (deployment tools, update checkers, custom automation, etc.)
    # should prefer these over hard-coded paths.
    # They are provided via home.sessionVariables so they are available in
    # any shell that Home Manager manages (zsh today, bash/fish/etc. in the future).
    NIX_HOME_MANAGER_FLAKE = "$HOME/src/nix-home-manager";
    NIX_HOME_MANAGER_CONFIGS_DIR = "$HOME/src/nix-home-manager";
    NIXOS_CONFIGS_DIR = "$HOME/src/nixos-configs";
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

  # Tiny convenience for the two (now three) path variables that helper scripts
  # (homectl, update checkers, custom automation, etc.) rely on.
  home.packages = [
    (pkgs.writeShellScriptBin "hm-paths" ''
      echo "NIX_HOME_MANAGER_FLAKE=$NIX_HOME_MANAGER_FLAKE"
      echo "NIX_HOME_MANAGER_CONFIGS_DIR=$NIX_HOME_MANAGER_CONFIGS_DIR"
      echo "NIXOS_CONFIGS_DIR=$NIXOS_CONFIGS_DIR"
    '')

    # homectl - installed into PATH after switch so it's always available for
    # easy `homectl switch` / info / generations on this machine.
    # Passed from the flake (homectlFor) so we don't rely on source tree paths
    # during evaluation (avoids issues with dirty/untracked files in flakes).
    homectl
  ];
}
