{ config, pkgs, lib, ... }:

{
  # Personal-only background update checker for gschwim's repos.
  # This module is for the maintainer's setup only.
  # Forks: delete this file and its import.

  # The script is provided by home.file in home.nix or here.
  # (moved to keep together)

  home.file.".local/bin/check-repo-updates" = {
    source = ./check-repo-updates;
    executable = true;
  };

  # Systemd user timer to run the check hourly (Linux only).
  # This runs completely outside the shell, no bg jobs in zsh.
  # On non-systemd systems (Ubuntu/Mint), use cron instead (see comments in this file).
  # On macOS, equivalent launchd plist can be added.
  systemd.user.services."check-nix-repos" = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Check for updates in personal Nix repos (nix-home-manager, nixos-configs)";
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "check-nix-repos" ''
        set -eu
        ${config.home.homeDirectory}/.local/bin/check-repo-updates \
          https://github.com/gschwim/nix-home-manager.git \
          ${config.home.homeDirectory}/src/nix-home-manager
        ${config.home.homeDirectory}/.local/bin/check-repo-updates \
          https://github.com/gschwim/nixos-configs.git \
          ${config.home.homeDirectory}/src/nixos-configs
      '';
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

  # Optional: run on login once
  systemd.user.services."check-nix-repos-on-login" = {
    Unit = {
      Description = "One-time check for personal Nix repos on login";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "check-nix-repos-login" ''
        ${config.home.homeDirectory}/.local/bin/check-repo-updates \
          https://github.com/gschwim/nix-home-manager.git \
          ${config.home.homeDirectory}/src/nix-home-manager
        ${config.home.homeDirectory}/.local/bin/check-repo-updates \
          https://github.com/gschwim/nixos-configs.git \
          ${config.home.homeDirectory}/src/nixos-configs
      '';
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
