# devshells/rust-stable.nix
#
# Stable Rust devShell (proof-of-concept for non-Python languages).
# One file per devshell (user preference) for easy review and maintenance.
#
# Usage:
#   nix develop .#rust-stable
#   # or via direnv:  use flake .#rust-stable

pkgs:

pkgs.mkShell {
  name = "rust-stable";

  packages = with pkgs; [
    rustc
    cargo
    rust-analyzer
    clippy
    rustfmt

    # Common native deps for Rust crates that build C code
    stdenv.cc
    pkg-config
    openssl
  ];

  shellHook = ''
    echo "🦀 Rust stable devShell (nixpkgs-25.11 / 26.05-darwin pin)"
    echo "rustc: $(rustc --version)"
    echo "cargo: $(cargo --version)"
    echo ""
    echo "Typical workflow:"
    echo "  cargo build"
    echo "  cargo test"
    echo "  cargo clippy"
    echo ""
    echo "Dropping into your normal zsh..."
    exec zsh -i
  '';
}
