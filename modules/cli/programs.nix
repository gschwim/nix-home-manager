{ config, pkgs, ... }:
let 

  # shellAliases = import ./shell.nix { inherit shellAliases; }; 
  inherit (import ./variables.nix) shellAliases configStarship;

in
{
  programs = {

    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    # my stuff here
    starship = {
      enable = true;
      settings = configStarship;
    };

    zsh =  {
      enable = true;
      zprof.enable = false;
      dotDir = "${config.home.homeDirectory}/.config/zsh";
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
      initContent = ''
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

        # ------------------------------------------------------------------
        # Dev shell helpers from your nix-home-manager checkout
        # ------------------------------------------------------------------
        # These give you short, path-free commands from *any* directory.
        #
        # Recommended one-time setup per machine (makes direnv + direct use even shorter):
        #   nix registry add nix-home-manager "$HOME/src/nix-home-manager"
        #
        # Then you can use the short name "nix-home-manager" everywhere.
        #
        # The functions below work even without the registry (they resolve the path).
        # Set NIX_HOME_MANAGER_FLAKE if your checkout is not in the default location.
        : "''${NIX_HOME_MANAGER_FLAKE:=$HOME/src/nix-home-manager}"

        dev() {
          nix develop "''${NIX_HOME_MANAGER_FLAKE}#$1" "''${@:2}"
        }

        # Very short aliases for daily use
        alias py313='dev python313-poetry'
        alias py312='dev python312-poetry'
        alias devrust='dev rust-stable'

        # Examples:
        #   py313
        #   dev python313-poetry --command python -c 'import sys; print(sys.executable)'
        #   devrust
        #   py313 --command poetry --version

        # === PERSONAL-ONLY: nix-home-manager + nixos-configs UPDATE CHECKER ===
        # This entire block is ONLY for the maintainer's (gschwim) personal machines and use.
        # If you forked this repo: DELETE from here to the "END PERSONAL-ONLY BLOCK" comment.
        # Other users/forks: you are on your own for repo update notifications.
        # Features:
        # - Background (non-blocking) checks for the two personal repos under ~/src.
        # - Auto-clones the repo(s) if the dir is missing (e.g. new system install).
        # - Rate limited (~1h).
        # - Notifies once per shell via message if updates pending.
        # - Uses existing NIX_HOME_MANAGER_FLAKE; adds NIXOS_CONFIGS_DIR.
        # - Generic checker script allows future use from bash etc.
        # Disable: NIX_HM_UPDATE_CHECK_INTERVAL=0 or remove this block.
        : "''${NIX_HOME_MANAGER_FLAKE:=$HOME/src/nix-home-manager}"
        : "''${NIXOS_CONFIGS_DIR:=$HOME/src/nixos-configs}"

        _personal_check_repos() {
          command -v check-repo-updates >/dev/null 2>&1 || return
          check-repo-updates "https://github.com/gschwim/nix-home-manager.git" "$NIX_HOME_MANAGER_FLAKE" &
          check-repo-updates "https://github.com/gschwim/nixos-configs.git" "$NIXOS_CONFIGS_DIR" &
        }

        _personal_show_repo_updates() {
          local cache_root="''${XDG_CACHE_HOME:-$HOME/.cache}/repo-updates"
          local msg=""
          if [ -f "$cache_root/nix-home-manager/status" ]; then
            local c=$(cat "$cache_root/nix-home-manager/status")
            msg="''${msg}%F{yellow}⚠ nix-home-manager has $c new commit(s) on remote.%f "
          fi
          if [ -f "$cache_root/nixos-configs/status" ]; then
            local c=$(cat "$cache_root/nixos-configs/status")
            msg="''${msg}%F{yellow}⚠ nixos-configs has $c new commit(s) on remote.%f "
          fi
          if [ -n "$msg" ]; then
            print -P "$msg cd \$dir && git pull && appropriate switch/rebuild."
            rm -f "$cache_root"/*/status 2>/dev/null || true
          fi
        }

        # Trigger background checks (rate limited inside the script)
        _personal_check_repos

        # Show notifications on prompt if pending
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd _personal_show_repo_updates

        # Manual command
        nix-home-manager-check-updates() {
          command -v check-repo-updates >/dev/null 2>&1 || { echo "check-repo-updates not found"; return 1; }
          check-repo-updates "https://github.com/gschwim/nix-home-manager.git" "$NIX_HOME_MANAGER_FLAKE" 0
          check-repo-updates "https://github.com/gschwim/nixos-configs.git" "$NIXOS_CONFIGS_DIR" 0
          _personal_show_repo_updates
        }
        alias hm-check-updates='nix-home-manager-check-updates'

        # END PERSONAL-ONLY BLOCK

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
    tmux = {
      enable = true;
      terminal = "screen-256color";
      # terminal = "tmux-256color";
      baseIndex = 1;
      mouse = true;
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
    eza = {
      enable = true;
      enableZshIntegration = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
        "--git"
      ];
    };

    # bat
    bat = {
      enable = true;
      config = {
        theme = "OneHalfDark";
      };
    };

    # ripgrep
    ripgrep.enable = true;

    # neovim
    # The actual configuration (init.lua + plugins via lazy.nvim) is managed
    # via xdg.configFile."nvim" sourcing the dotfiles.nvim flake input.
    neovim = {
      enable = true;
      defaultEditor = true;
      withRuby = false;
      withPython3 = false;

      # Add tools that are commonly useful for Neovim configs (LSP, formatters, etc.)
      # Many are already in the user's general packages, but listed here for the Neovim env.
      extraPackages = with pkgs; [
        # Common language servers / tools can be added here as needed
      ];
    };

    fzf = {
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

    git = {
      enable = true;
      settings = {
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

    delta = {
      enable = true;
      enableGitIntegration = true;
    };

    # deprecated
    # thefuck = {
    #   enable = true;
    #   enableZshIntegration = true;
    # };
    
    pay-respects = {
      enable = true;
      enableZshIntegration = true;
      options = [
        "--alias"
        "thefuck"
      ];
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      # options = {};
    };
    btop = { enable = true; };
    htop = { enable = true; };
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      
    };
  };
}
