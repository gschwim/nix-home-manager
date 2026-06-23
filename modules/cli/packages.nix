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
    # Daily global Python (the "always there" one after switch, for ad-hoc scripts,
    # quick `python -c`, and Jupyter notebooks started from anywhere).
    # Project work should use the devShells (py313 / py312) + Poetry.
    #
    # metpy and siphon are built directly here from their official PyPI releases
    # (https://github.com/Unidata/MetPy and https://github.com/Unidata/siphon)
    # because they are not (yet) in the pinned nixpkgs snapshots used by this flake.
    (pkgs.python3.withPackages (ps:
      let
        siphon = ps.buildPythonPackage rec {
          pname = "siphon";
          version = "0.10.0";
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "f99ff44568805d5c00c0599019302a4ea4874d861f00996c8b7de6de4d543f7b";
          };
          pyproject = true;
          build-system = with ps; [ setuptools setuptools-scm wheel ];
          env.SETUPTOOLS_SCM_PRETEND_VERSION = version;
          propagatedBuildInputs = with ps; [
            beautifulsoup4
            numpy
            pandas
            protobuf
            requests
          ];
          doCheck = false;
        };
        metpy = ps.buildPythonPackage rec {
          pname = "metpy";
          version = "1.7.1";
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "cdfd8fdab58bc092a1974c016f2ea3a7715ffdf6a4660b28b0de7049328bce75";
          };
          pyproject = true;
          build-system = with ps; [ setuptools setuptools-scm wheel ];
          env.SETUPTOOLS_SCM_PRETEND_VERSION = version;
          propagatedBuildInputs = with ps; [
            matplotlib
            numpy
            pandas
            pint
            pooch
            pyproj
            scipy
            traitlets
            xarray
          ];
          doCheck = false;
        };
      in
      with ps; [
        jupyterlab
        jupyterlab-vim
        polars
        matplotlib
        numpy
        pandas
        seaborn
        ipython
        ipywidgets
        siphon
        metpy
      ]
    ))
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
