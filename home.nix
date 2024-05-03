{ config, pkgs, ... }:

let
  shellAliases = {
    cat = "bat";
    cd = "z";
    less = "bat";
    vim = "nvim";
    vi = "nvim";
    nv = "nvim";
    ls = "eza -l";
    ll = "eza -l";
    la = "eza -a";
    history = "history -f";
    ga = "git add";
    gaa = "git add --all";
    gapa = "git add --patch";
    gau = "git add --update";
    gav = "git add --verbose";
    g = "git git";
    gb = "git branch";
    gba = "git branch --all";
    gbd = "git branch --delete";
    gco = "git checkout";
    gcor = "git checkout --recurse-submodules";
    gcb = "git checkout -b";
    gcB = "git checkout -B";
    gcd = "git checkout $(git_develop_branch)";
    gcm = "git checkout $(git_main_branch)";
    gcmsg = "git commit --message";
    gc = "git commit --verbose";
    gca = "git commit --verbose --all";
    glgg = "git log --graph";
    glgga = "git log --graph --decorate --all";
    glgm = "git log --graph --max-count=10";
    glods = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset\" --date=short";
    glod = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset\"";
    glola = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset\" --all";
    glols = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset\" --stat";
    glol = "git log --graph --pretty=\"%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset\"";
    glo = "git log --oneline --decorate";
    glog = "git log --oneline --decorate --graph";
    gloga = "git log --oneline --decorate --graph --all";
    glp = "git _git_log_prettily";
    glg = "git log --stat";
    glgp = "git log --stat --patch";
    gp = "git push";
    gpd = "git push --dry-run";
    # gpf! = "git push --force";
    gpsup = "git push --set-upstream origin $(git_current_branch)";
    gpv = "git push --verbose";
    gke = "git \gitk --all $(git log --walk-reflogs --pretty=%h) &!";
    grt = "git cd \"$(git rev-parse --show-toplevel || echo .)\"";
    ggpur = "git ggu";
    gwip = "git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message \"--wip-- [skip ci]\"";
    gam = "git am";
    gama = "git am --abort";
    gamc = "git am --continue";
    gamscp = "git am --show-current-patch";
    gams = "git am --skip";
    gap = "git apply";
    gapt = "git apply --3way";
    gbs = "git bisect";
    gbsb = "git bisect bad";
    gbsg = "git bisect good";
    gbsn = "git bisect new";
    gbso = "git bisect old";
    gbsr = "git bisect reset";
    gbss = "git bisect start";
    gbl = "git blame -w";
    gbD = "git branch --delete --force";
    gbgd = "git LANG=C git branch --no-color -vv | grep \": gone\]\" | awk '\"'\"'{print $1}'\"'\"' | xargs git branch -d";
    gbgD = "git LANG=C git branch --no-color -vv | grep \": gone\]\" | awk '\"'\"'{print $1}'\"'\"' | xargs git branch -D";
    gbm = "git branch --move";
    gbnm = "git branch --no-merged";
    gbr = "git branch --remote";
    ggsup = "git branch --set-upstream-to=origin/$(git_current_branch)";
    gbg = "git LANG=C git branch -vv | grep \": gone\]\"";
    gcp = "git cherry-pick";
    gcpa = "git cherry-pick --abort";
    gcpc = "git cherry-pick --continue";
    gclean = "git clean --interactive -d";
    gcl = "git clone --recurse-submodules";
    gcam = "git commit --all --message";
    gcas = "git commit --all --signoff";
    gcasm = "git commit --all --signoff --message";
    gcs = "git commit --gpg-sign";
    gcss = "git commit --gpg-sign --signoff";
    gcssm = "git commit --gpg-sign --signoff --message";
    gcsm = "git commit --signoff --message";
    # gca! = "git commit --verbose --all --amend";
    # gcan! = "git commit --verbose --all --no-edit --amend";
    # gcans! = "git commit --verbose --all --signoff --no-edit --amend";
    # gcann! = "git commit --verbose --all --date=now --no-edit --amend";
    # gc! = "git commit --verbose --amend";
    # gcn! = "git commit --verbose --no-edit --amend";
    gcf = "git config --list";
    gdct = "git describe --tags $(git rev-list --tags --max-count=1)";
    gd = "git diff";
    gdca = "git diff --cached";
    gdcw = "git diff --cached --word-diff";
    gds = "git diff --staged";
    gdw = "git diff --word-diff";
    gdup = "git diff @{upstream}";
    gdt = "git diff-tree --no-commit-id --name-only -r";
    gf = "git fetch";
    gfo = "git fetch origin";
    gg = "git gui citool";
    gga = "git gui citool --amend";
    ghh = "git help";
    gignored = "git ls-files -v | grep \"^[[:lower:]]\"";
    gfg = "git ls-files | grep";
    gm = "git merge";
    gma = "git merge --abort";
    gmc = "git merge --continue";
    gms = "git git merge --squash";
    gmom = "git merge origin/$(git_main_branch)";
    gmum = "git merge upstream/$(git_main_branch)";
    gmtl = "git mergetool --no-prompt";
    gmtlvim = "git mergetool --no-prompt --tool=vimdiff";
    gl = "git pull";
    gpr = "git pull --rebase";
    gprv = "git pull --rebase -v";
    gpra = "git pull --rebase --autostash";
    gprav = "git pull --rebase --autostash -v";
    gprom = "git pull --rebase origin $(git_main_branch)";
    gpromi = "git pull --rebase=interactive origin $(git_main_branch)";
    # original: ggpull = "git pull origin "$(git_current_branch)"";
    ggpull = "git pull origin $(git_current_branch)";
    gluc = "git pull upstream $(git_current_branch)";
    glum = "git pull upstream $(git_main_branch)";
    gpoat = "git push origin --all && git push origin --tags";
    gpod = "git push origin --delete";
    ggpush = "git push origin $(git_current_branch)";
    gpu = "git push upstream";
    grb = "git rebase";
    grba = "git rebase --abort";
    grbc = "git rebase --continue";
    grbi = "git rebase --interactive";
    grbo = "git rebase --onto";
    grbs = "git rebase --skip";
    grbd = "git rebase $(git_develop_branch)";
    grbm = "git rebase $(git_main_branch)";
    grbom = "git rebase origin/$(git_main_branch)";
    grf = "git reflog";
    gr = "git remote";
    grv = "git remote --verbose";
    gra = "git remote add";
    grrm = "git remote remove";
    grmv = "git remote rename";
    grset = "git remote set-url";
    grup = "git remote update";
    grh = "git reset";
    gru = "git reset --";
    grhh = "git reset --hard";
    grhk = "git reset --keep";
    grhs = "git reset --soft";
    gpristine = "git reset --hard && git clean --force -dfx";
    gwipe = "git reset --hard && git clean --force -df";
    groh = "git reset origin/$(git_current_branch) --hard";
    grs = "git restore";
    grss = "git restore --source";
    grst = "git restore --staged";
    gunwip = "git rev-list --max-count=1 --format=\"%s\" HEAD | grep -q \"\--wip--\" && git reset HEAD~1";
    grev = "git revert";
    greva = "git revert --abort";
    grevc = "git revert --continue";
    grm = "git rm";
    grmc = "git rm --cached";
    gcount = "git shortlog --summary --numbered";
    gsh = "git show";
    gsps = "git show --pretty=short --show-signature";
    gstall = "git stash --all";
    gstaa = "git stash apply";
    gstc = "git stash clear";
    gstd = "git stash drop";
    gstl = "git stash list";
    gstp = "git stash pop";
    gsts = "git stash show --patch";
    gst = "git status";
    gss = "git status --short";
    gsb = "git status --short --branch";
    gsi = "git submodule init";
    gsu = "git submodule update";
    gsd = "git svn dcommit";
    git-svn-dcommit-push = "git svn dcommit && git push github $(git_main_branch):svntrunk";
    gsr = "git svn rebase";
    gsw = "git switch";
    gswc = "git switch --create";
    gswd = "git switch $(git_develop_branch)";
    gswm = "git switch $(git_main_branch)";
    gta = "git tag --annotate";
    gts = "git tag --sign";
    gtv = "git tag | sort -V";
    gignore = "git update-index --assume-unchanged";
    gunignore = "git update-index --no-assume-unchanged";
    gwch = "git whatchanged -p --abbrev-commit --pretty=medium";
    gwt = "git worktree";
    gwta = "git worktree add";
    gwtls = "git worktree list";
    gwtmv = "git worktree move";
    gwtrm = "git worktree remove";
    gstu = "git gsta --include-untracked";
    # gtl = "git gtl(){ git tag --sort=-v:refname -n --list \"${1}*\" }; noglob gtl";
    gk = "git \gitk --all --branches &!";
    # gke = "git \gitk --all $(git log --walk-reflogs --pretty=%h) &!";
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
    pkgs.gcc_multi
    pkgs.dust
    pkgs.fd
    pkgs.tlrc
    # pkgs.bat
    # pkgs.stable.rust
    
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
    dotDir = ".config/zsh";
    autosuggestion.enable = true;
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
          rev = "main";
          sha256 = "wSBcmshT/Jbk5UzGMOhCq+Kj2rzxLUPcqdf9SChHkps=";
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
      bindkey "^[OA" up-line-or-beginning-search # Up
      bindkey "^[OB" down-line-or-beginning-search # Down
      # bindkey "^[[A" up-line-or-beginning-search # Up
      # bindkey "^[[B" down-line-or-beginning-search # Down

    '';


  };

  # tmux
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    historyLimit = 100000;
    plugins = with pkgs; [
      tmuxPlugins.cpu
      tmuxPlugins.onedark-theme
    ];
    # vim doesn't like the default of 500
    escapeTime = 10;
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

  # pyenv
  programs.pyenv = {
    enable = true;
    enableZshIntegration = true;
  };
  
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
}
