{ config, pkgs, lib, ... }:
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
        # zsh-vi-mode must be the first plugin so that its vi-mode keybindings
        # are initialized early. Other plugins and custom bindings (in initContent)
        # can then coexist with it.
        # See https://github.com/jeffreytse/zsh-vi-mode
        {
          name = "zsh-vi-mode";
          src = pkgs.zsh-vi-mode;
          file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        }

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

      initContent = lib.mkMerge [
        (lib.mkBefore ''
          # zsh-vi-mode options (see https://github.com/jeffreytse/zsh-vi-mode)
          # These must be set *before* the plugin is sourced.
          # Use 'jk' (or 'jj') as escape from insert mode. This is the classic
          # vim-user tweak that avoids the ESC delay and feels natural.
          ZVM_VI_INSERT_ESCAPE_BINDKEY=jk

          # ZVM_CURSOR_STYLE_ENABLED=false

          # Restore the fzf-powered ctrl-R history widget in insert mode.
          # (zsh-vi-mode takes over keymaps; this runs in zvm_after_init after
          # viins is initialized, so we get the nice fzf popup with scrollable
          # fuzzy matches instead of plain incremental search.)
          #
          # In normal mode, / and ? still work for vi-style history search.
          zvm_after_init() {
            bindkey -M viins '^R' fzf-history-widget
          }
        '')
        ''
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
        : "''${NIX_HOME_MANAGER_CONFIGS_DIR:=$HOME/src/nix-home-manager}"

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
        # This block is ONLY for the maintainer's (gschwim) personal machines.
        # Forkers/other users: DELETE this entire PERSONAL block.
        # It is not part of the reusable config.
        #
        # How it works now (per user request):
        # - No more background jobs launched from the shell.
        # - A systemd user timer (Linux/NixOS, including headless) or launchd agent
        #   (macOS/Darwin) periodically runs ~/.local/bin/check-repo-updates for the two repos.
        #   (See modules/personal/update-checker.nix for the units + cron examples for Ubuntu/Mint.)
        # - The script updates status files in $XDG_CACHE_HOME/repo-updates/*/status (or ~/.cache)
        #   (contains commit count if behind; cleaned when up-to-date).
        # - Starship custom module (below) shows a "🔄" indicator in the prompt
        #   if any status file exists. Purely passive signal.
        # - Manual trigger still works: hm-check-updates (forces check, updates status).
        # - Auto-clone: if ~/src/* missing, the script (when run) will clone.
        #
        # The external scheduler (systemd/launchd) runs the checks. Shell only reads fast status files.
        : "''${NIX_HOME_MANAGER_FLAKE:=$HOME/src/nix-home-manager}"
        : "''${NIX_HOME_MANAGER_CONFIGS_DIR:=$HOME/src/nix-home-manager}"
        : "''${NIXOS_CONFIGS_DIR:=$HOME/src/nixos-configs}"

        # Manual force check (updates the status files that Starship reads)
        nix-home-manager-check-updates() {
          command -v check-repo-updates >/dev/null 2>&1 || { echo "check-repo-updates not found in PATH"; return 1; }
          check-repo-updates "https://github.com/gschwim/nix-home-manager.git" "$NIX_HOME_MANAGER_FLAKE" 0
          check-repo-updates "https://github.com/gschwim/nixos-configs.git" "$NIXOS_CONFIGS_DIR" 0
          echo "Update check forced. Status files updated. Prompt indicator will reflect on next prompt."
        }
        alias hm-check-updates='nix-home-manager-check-updates'

        # END PERSONAL-ONLY BLOCK

        # Source the user's generic local rc file *last* (after all HM code).
        # This file is staged empty by home.activation and is 100% user-owned.
        # The user can safely add/override anything here, including the NIX_* path
        # environment variables.
        [[ -f ~/.localrc ]] && source ~/.localrc

        # (Temporary compatibility for anyone who already edited the old location.
        # Will be removed in a future cleanup.)
        [[ -f ~/.config/zsh/zshrc_local ]] && source ~/.config/zsh/zshrc_local
      ''
    ];


    };

  # Seed the generic local-only rc file once (if it does not exist).
  # The file contains only a header; the user owns it forever after.
  # It is sourced last from the zsh initContent (see above) so the user
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
      prefix = "C-b";

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

  # Seed the generic local-only rc file once (if it does not exist).
  # The file contains only a header; the user owns it forever after.
  # It is sourced last from the zsh initContent (see above) so the user
  # can add/override anything, including the NIX_* path variables.
  home.activation.seedLocalRc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "$HOME/.localrc" ]; then
      cat > "$HOME/.localrc" << 'EOF'
# ~/.localrc
#
# LOCAL-ONLY FILE — Home Manager will never overwrite or manage this file
# after the initial creation.
#
# Source this file at the very end of your shell rc / login files
# (from zsh, bash, fish, or any other shell).
#
# You can use it to add, remove, or override any environment variables,
# aliases, functions, etc. that were set earlier by Home Manager,
# including:
#   NIX_HOME_MANAGER_CONFIGS_DIR
#   NIXOS_CONFIGS_DIR
#   NIX_HOME_MANAGER_FLAKE
#
# This file is completely safe for you to edit, delete, or put under
# your own version control outside this repository.
#
# homectl (the deployment helper) relies on the NIX_* vars and can be used
# for `homectl switch` (auto target from /etc/nixos-host-info + hostname etc).
EOF
    fi
  '';
}
