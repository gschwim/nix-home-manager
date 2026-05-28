# devshells/python312-poetry.nix
#
# Thin Poetry-first devShell for Python 3.12.
# One file per devshell (user preference) for easy review and maintenance.
#
# Usage:
#   nix develop .#python312-poetry
#   # or via direnv:  use flake .#python312-poetry
#
# Design:
# - Poetry manages its own lockfile + venvs (we do not use poetry2nix by default).
# - We only supply a good Python + Poetry + the native build deps that most
#   projects need for wheels with C extensions.
# - Keep the shellHook minimal and non-brittle.

pkgs:

pkgs.mkShell {
  name = "python312-poetry";

  packages = with pkgs; [
    python312
    poetry
    python312.pkgs.pip   # explicit pip for ad-hoc needs inside the shell

    # Common Python dev tools that play nicely with Poetry-managed projects
    ruff
    black

    # Native build / compilation toolchain (common for Python wheels)
    stdenv.cc
    pkg-config
    openssl
    # Add more per-project as needed (e.g. libffi, zlib, postgresql, etc.)
  ];

  shellHook = ''
    echo "🐍 Python 3.12 + Poetry devShell (nixpkgs-25.11 / 26.05-darwin pin)"
    echo ""
    echo "Normal Poetry workflow:"
    echo "  poetry install"
    echo "  poetry run python ..."
    echo "  poetry shell          # optional"
    echo ""
    echo "Dropping into your normal zsh..."
    exec zsh -i
  '';
}
