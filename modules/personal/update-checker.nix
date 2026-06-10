{ config, pkgs, lib, ... }:

let
  # Shared wrapper used by both the systemd units (Linux) and launchd agents (Darwin).
  # Runs the two repo checks using the deployed POSIX script.
  # We use absolute paths so it works even with minimal env from the scheduler.
  #
  # On fresh installs there can be a race between this service starting (via
  # default.target or RunAtLoad) and home-manager finishing its activation
  # (which creates the ~/.local/bin/check-repo-updates via home.file).
  # We therefore guard the call so we exit cleanly (0) instead of failing the
  # unit with status 127 ("command not found").
  checkNixReposScript = pkgs.writeShellScript "check-nix-repos" ''
    set -eu

    CHECKER="${config.home.homeDirectory}/.local/bin/check-repo-updates"

    if [ ! -x "$CHECKER" ]; then
      echo "check-repo-updates not yet deployed (Home Manager activation probably still in progress on first switch/login). Skipping this run." >&2
      exit 0
    fi

    "$CHECKER" \
      https://github.com/gschwim/nix-home-manager.git \
      ${config.home.homeDirectory}/src/nix-home-manager
    "$CHECKER" \
      https://github.com/gschwim/nixos-configs.git \
      ${config.home.homeDirectory}/src/nixos-configs
  '';
in
{
  # =====================================================================
  # PERSONAL-ONLY: Background repo update checker (maintainer gschwim only)
  # =====================================================================
  # Forks: delete this entire module + its import in home.nix + the
  # PERSONAL-ONLY block in programs.nix + the custom starship section in
  # variables.nix. See README "Personal Update Notifications (Maintainer Only)".
  #
  # Design goals (per requirements):
  # - No shell background jobs (& or precmd). Completely external.
  # - Uses systemd user timers (Linux/NixOS) or launchd agents (macOS/Darwin).
  # - On non-systemd Linux (Ubuntu/Mint) the user can set up equivalent via
  #   cron (see bottom of this file for example lines).
  # - Writes status files to $XDG_CACHE_HOME/repo-updates/*/status (or ~/.cache)
  #   which the Starship prompt module reads with cheap test -f (passive only).
  # - Auto-clones the repos under ~/src on first run if missing (new machine).
  # - Manual override still available via hm-check-updates alias.
  # - Ensures nix-provided git is used (via PATH) so no Xcode license nag on Darwin.
  #
  # Note on fresh installs: there can be a small race between user services
  # starting (WantedBy default.target / RunAtLoad) and the Home Manager
  # activation finishing (home.file creation of ~/.local/bin/check-repo-updates).
  # Both the generated wrappers and the on-login unit have guards so this
  # results in a clean skip rather than a failed unit (status 127).
  # =====================================================================

  # Deploy the generic POSIX checker script (cross-platform).
  home.file.".local/bin/check-repo-updates" = {
    source = ./check-repo-updates;
    executable = true;
  };

  # ------------------------------------------------------------------
  # Linux: systemd user timer + on-login oneshot (headless friendly)
  # ------------------------------------------------------------------
  systemd.user.services."check-nix-repos" = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Check for updates in personal Nix repos (nix-home-manager, nixos-configs)";
      After = [ "home-manager-session.target" ];
      ConditionPathExists = "${config.home.homeDirectory}/.local/bin/check-repo-updates";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${checkNixReposScript}";
      # Prefer nix git (and other profile tools) over system git.
      # Critical on macOS too but launchd uses its own key below.
      Environment = [
        "PATH=${config.home.profileDirectory}/bin:/usr/local/bin:/usr/bin:/bin"
      ];
    };
  };

  systemd.user.timers."check-nix-repos" = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Periodic check for personal Nix repo updates";
    };
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "5min";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # One-shot on login (or boot for headless). Works on CLI-only servers
  # (no graphical-session dep, unlike some desktop-oriented units).
  #
  # We add After + ConditionPathExists to reduce races on fresh Home Manager
  # activations (the home.file that creates ~/.local/bin/check-repo-updates
  # must exist before we try to run). The script wrapper below is also
  # defensive and will exit 0 (instead of failing the unit) if the checker
  # isn't present yet.
  systemd.user.services."check-nix-repos-on-login" = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "One-time check for personal Nix repos on login/boot";
      After = [ "home-manager-session.target" ];
      ConditionPathExists = "${config.home.homeDirectory}/.local/bin/check-repo-updates";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${checkNixReposScript}";
      Environment = [
        "PATH=${config.home.profileDirectory}/bin:/usr/local/bin:/usr/bin:/bin"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # ------------------------------------------------------------------
  # Darwin / macOS: launchd user agents (equivalent to the systemd timers)
  # ------------------------------------------------------------------
  # Home Manager translates this into ~/Library/LaunchAgents/<label>.plist
  # and handles bootstrap/load via launchctl during activation.
  # Uses the same check script. RunAtLoad + StartInterval gives "on login + hourly".
  # We use "Program" (not ProgramArguments + /bin/sh -c) for cleanliness.
  #
  # On some macOS versions the Home Manager launchd activation can hit
  # "Unrecognized target specifier" or "I/O error (code 5)" if a previous
  # generation's agent is still loaded under the same label. We do a
  # best-effort pre-cleanup right before setupLaunchAgents.
  #
  # The commands use the modern separate domain + label form.
  home.activation.unloadStaleCheckNixReposAgent = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryBefore ["setupLaunchAgents"] ''
      echo "Cleaning up any stale com.user.check-nix-repos launch agent (best effort)..."
      /bin/launchctl bootout "gui/$(id -u)" "com.user.check-nix-repos" 2>/dev/null || true
      /bin/launchctl remove "com.user.check-nix-repos" 2>/dev/null || true
    ''
  );

  launchd.agents."check-nix-repos" = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      Label = "com.user.check-nix-repos";
      # Direct executable (the wrapper we built above has #!/nix/store...sh inside).
      Program = "${checkNixReposScript}";
      RunAtLoad = true;      # run soon after login / when agent is loaded
      StartInterval = 3600;  # seconds -> hourly
      # Make sure the job sees the HM profile first (nix git, etc.).
      # Without this we would hit /usr/bin/git which nags for Xcode license on this machine.
      EnvironmentVariables = {
        PATH = "${config.home.profileDirectory}/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      # Logs for debugging (view with: cat ~/Library/Logs/check-nix-repos.*.log)
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/check-nix-repos.out.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/check-nix-repos.err.log";
    };
  };

  # ------------------------------------------------------------------
  # Cron example for Ubuntu/Mint or other non-systemd (user can copy-paste)
  # ------------------------------------------------------------------
  # crontab -e
  # @hourly $HOME/.local/bin/check-repo-updates https://github.com/gschwim/nix-home-manager.git $HOME/src/nix-home-manager
  # @hourly $HOME/.local/bin/check-repo-updates https://github.com/gschwim/nixos-configs.git $HOME/src/nixos-configs
  #
  # Or use "at" for one-offs, or a systemd --user timer on distros that have it.
  # The script itself is rate-limited and silent on success.
}
