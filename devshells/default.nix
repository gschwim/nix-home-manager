{
  nixpkgs-25-11,
  nixpkgs-26-05-darwin,
}:
let
  # Individual devshell modules (one file per shell per user's preference).
  # Each exports a function: pkgs -> derivation (the mkShell).
  # Called as `theFn pkgs` (bare pkgs value, not an attrset).
  python312Poetry = import ./python312-poetry.nix;
  python313Poetry = import ./python313-poetry.nix;
  rustStable      = import ./rust-stable.nix;

  # Helper: build the attrset of shells for one nixpkgs pin + system.
  mkShellsFor = pkgs: {
    python312-poetry = python312Poetry pkgs;
    python313-poetry = python313Poetry pkgs;
    rust-stable      = rustStable pkgs;
    # Add small ad-hoc convenience shells here later if desired (see open questions).
  };
in
{
  # These are the exact outputs expected by the root flake.nix.
  x86_64-linux = mkShellsFor nixpkgs-25-11.legacyPackages.x86_64-linux;

  x86_64-darwin = mkShellsFor nixpkgs-26-05-darwin.legacyPackages.x86_64-darwin;
}
