{ pkgs, ... }:
{
  home.packages = [
    pkgs.dust
    pkgs.fd
    pkgs.tlrc
    pkgs.wget
    pkgs.curl
    pkgs.git
    pkgs.difftastic
    pkgs.python3
    pkgs.poetry
    pkgs.yt-dlp

    ### vget for video grabs
    (pkgs.writeShellScriptBin "vget" ''
      yt-dlp --cookies-from-browser chrome $*
    '')

    # CLI / TUI analogues for desktop apps (networking + system engineering focus)
    # These live in the headless profile for parity without GUI dependencies.

    # Password management (keepassxc GUI analogue)
    pkgs.keepassxc

    # Cloud sync (dropbox GUI analogue) — excellent for rclone + many backends
    pkgs.rclone

    # Secure messaging (signal-desktop analogue)
    pkgs.signal-cli

    # Networking & packet analysis
    pkgs.wireshark
    pkgs.termshark
    pkgs.nmap
    pkgs.tcpdump
    pkgs.iperf3
    pkgs.socat
    pkgs.netcat
    pkgs.dig
    pkgs.whois

    # System monitoring & performance (headless-friendly)
    pkgs.glances
    pkgs.btop

    # Knowledge base / notes (obsidian analogue for headless)
    pkgs.glow

    # Editors — we already have neovim as defaultEditor
    # (vscodium is desktop-only)

    # Terminals — we have a very rich tmux + zsh setup
    # (wezterm is desktop-only)
  ];

}
