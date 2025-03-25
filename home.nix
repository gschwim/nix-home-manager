{ config, pkgs, ... }:


let

  inherit (import ./shell.nix) shellAliases configStarship;

    # dev environments flakes
  devEnvs = import environments/python { inherit pkgs; };

in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  # home.username = "schwim2";
  # home.homeDirectory = "/home/schwim2";
  # home.username = builtins.getEnv "USER";
  home.username = "schwim";
  # home.homeDirectory = "/Users/schwim";
  home.homeDirectory = builtins.getEnv "HOME";
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
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.

    # presumably for python. It builds, but so many things are missing. Sad.
    # pkgs.hello
    # pkgs.gcc_multi
    # pkgs.gnumake
    # pkgs.gdb
    # pkgs.lcov
    # pkgs.unzip
    # pkgs.pkg-config
    # pkgs.zlib
    # pkgs.libffi
    # # pkgs.libbz2
    # pkgs.gdbm
    # #pkgs.gdbm-compat
    # pkgs.lzlib
    # pkgs.ncurses5
    # pkgs.readline
    # pkgs.sqlite
    # pkgs.libressl
    # # pkgs.lzma-dev
    # pkgs.tk
    # pkgs.stduuid
    # pkgs.zlib
    # pkgs.python39
    # pkgs.python312



    pkgs.dust
    pkgs.fd
    pkgs.tlrc
    pkgs.wget
    pkgs.curl
    pkgs.difftastic
    pkgs.python3
    pkgs.yt-dlp

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

    # rustup
    # pkgs.rustup

    (pkgs.writeShellScriptBin "vget" ''
      yt-dlp --cookies-from-browser chrome $*
    '')
    ### for dev environments flake
    (pkgs.writeShellScriptBin "python39-dev" ''
      nix develop ~/environments/python#python39-dev
    '')
    (pkgs.writeShellScriptBin "python311-dev" ''
      nix develop ~/environments/python#python311-dev
    '')
    (pkgs.writeShellScriptBin "python313-dev" ''
      nix develop ~/environments/python#python313-dev
    '')
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
    ZSH_AUTOSUGGEST_MANUAL_REBIND="True";
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
    zprof.enable = false;
    dotDir = ".config/zsh";
    autosuggestion.enable = true;
    completionInit = "autoload -U compinit && compinit -u";
    shellAliases = shellAliases;
    history = {
      extended = true;
      share = true;

    };
    plugins = [
      # fzf-git: https://github.com/junegunn/fzf-git.sh
      {
        name = "fzf-git";
        file = "fzf-git.sh";
        src = pkgs.fetchFromGitHub {
          owner = "junegunn";
          repo = "fzf-git.sh";
          # pinning to a specific commit as this appears to change from time to time
          # rev = "main";
          rev = "bd8ac4ba4c9d7d12b34f7fa2b0d334f50cdb5254";
          sha256 = "ZYgov/P7fcB1Zjj5UMVbr7+bjRKLwzpqddHBOCNd+RQ=";
        };
      }
    ];
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
      # These are for linux
      bindkey "^[OA" up-line-or-beginning-search # Up
      bindkey "^[OB" down-line-or-beginning-search # Down
      # These are for OSX
      bindkey "^[[A" up-line-or-beginning-search # Up
      bindkey "^[[B" down-line-or-beginning-search # Down
      
      # # pyenv activation
      # if [ -e ~/.pyenv/bin/pyenv ]; then
      #   export PYENV_ROOT="$HOME/.pyenv"
      #   [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
      #   eval "$(pyenv init -)"
      #   print "pyenv initialized!"
      # else
      #   print "pyenv init missing!"
      # fi

      # local overrides
      if [ -e ~/.config/zsh/zshrc_local ]; then
        source ~/.config/zsh/zshrc_local
      else
        print "zshrc_local does not exist. Created in ~/.config/zshrc to use."
        echo "# local overrides go here..." > ~/.config/zsh/zshrc_local
      fi
    '';


  };

  # tmux
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    # terminal = "tmux-256color";
    historyLimit = 100000;
    plugins = with pkgs; [
      tmuxPlugins.cpu
      tmuxPlugins.onedark-theme
      tmuxPlugins.vim-tmux-navigator
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g allow-passthrough on
          set -s set-clipboard on
        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
        '';
      }
    ];
    # change from the default prefix
    prefix = "C-a";

    # vi keybindings, not emacs
    keyMode = "vi";

    # vim doesn't like the default of 500
    escapeTime = 10;

    # general extraConfig
    extraConfig = "
      # window split rebinds
      unbind %
      bind | split-window -h 
      unbind '\"'
      bind - split-window -v

      # vi keys to resize panes, e.g. prefix-j, etc...
      bind j resize-pane -D 5
      bind k resize-pane -U 5
      bind l resize-pane -R 5
      bind h resize-pane -L 5
      bind -r m resize-pane -Z

      # vi-mode select and copy
      bind-key -T copy-mode-vi 'v' send -X begin-selection # start selecting text with 'v'
      bind-key -T copy-mode-vi 'y' send -X copy-selection # copy text with 'y'
      ";
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

  # bat
  programs.bat = {
    enable = true;
    config = {
      theme = "OneHalfDark";
    };
  };

  # ripgrep
  programs.ripgrep.enable = true;

  # neovim
  programs.neovim.enable = true;

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
    defaultOptions = [
      "--color=fg:\"#CBE0F0\",bg:\"#011628\",hl:\"#B388FF\",fg+:\"#CBE0F0\",bg+:\"#143652\",hl+:\"#B388FF\",info:\"#06BCE4\",prompt:\"#2CF9ED\",pointer:\"#2CF9ED\",marker:\"#2CF9ED\",spinner:\"#2CF9ED\",header:\"#2CF9ED\""
    ];

    fileWidgetCommand = "fd --hidden --strip-cwd-prefix --exclude .git";

    fileWidgetOptions = [
      "--preview"
      "'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
    ];
    changeDirWidgetOptions = [
      "--preview eza --tree --color=always {} | head -200"
    ];

  }; 

  # # pyenv - not sure this is acceptable to me
  # programs.pyenv = {
  #   enable = true;
  #   enableZshIntegration = true;
  # };
  
  programs.git = {
    enable = true;
    delta.enable = true;
    extraConfig = {

      # core = {
      #   pager = "delta";
      # };

      # interactive = {
      #   diffFilter = "delta --color-only";
      # };

      delta = {
        navigate = true;
        side-by-side = true;
        # dark = true;
        # light = true;
      };

      merge = {
        conflictstyle = "diff3";
      };

      diff.colorMoved = "default";

    };
  };

  programs.thefuck = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    # options = {};
  };
  programs.btop = { enable = true; };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    
  };
}
