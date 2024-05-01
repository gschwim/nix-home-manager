{ config, pkgs, ... }:

let
  shellAliases = {
    cat = "bat";
    less = "bat";
    vim = "nvim";
    vi = "nvim";
    nv = "nvim";
    ls = "eza -l";
    ll = "eza -l";
    la = "eza -a";
    history = "history -f";
  };
  configStarship = {
    # Get editor completions based on the config schema
    "$schema" = "https://starship.rs/config-schema.json";
    
    # Inserts a blank line between shell prompts
    add_newline = true;
    
    # Replace the '❯' symbol in the prompt with '➜'
    # The name of the module we are configuring is 'character'
    character.success_symbol = "[➜ ➜](bold green)"; # The "success_symbol" segment is being set to "➜" with the color "bold green"
    
    # Disable the package module, hiding it from the prompt completely
    package.disabled = true;
    
    container.format = "[$symbol$symbol]($style) ";
  };
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "schwim2";
  home.homeDirectory = "/home/schwim2";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello
    pkgs.dust
    pkgs.bat
    
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

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
  #  /etc/profiles/per-user/schwim2/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # my stuff here
  programs.starship = {
    enable = true;
    settings = configStarship;
  };
  programs.zsh =  {
    enable = true;
    autosuggestion.enable = true;
    shellAliases = shellAliases;
    initExtra = ''
      # added by Nix installer
      if [ -e /home/schwim2/.nix-profile/etc/profile.d/nix.sh ]; then
        . /home/schwim2/.nix-profile/etc/profile.d/nix.sh;
      fi

      # bindings for up/down history search
      autoload -U up-line-or-beginning-search
      autoload -U down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      bindkey "^[[A" up-line-or-beginning-search # Up
      bindkey "^[[B" down-line-or-beginning-search # Down
    '';
    history = {
      extended = true;
      share = true;

    };

  };

  #eza
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
      "--git"
    ];
  };

  # ripgrep
  programs.ripgrep.enable = true;

  # neovim
  programs.neovim.enable = true;

  # pyenv
  programs.pyenv = {
    enable = true;
    enableZshIntegration = true;
  };
  



}
