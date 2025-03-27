{
  description = "Global Python development environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgs-stable = nixpkgs-stable.legacyPackages.${system};
      in
      {
        devShells = {
          # Python 3.9 environment
          python39-dev = pkgs.mkShell {
            buildInputs = with pkgs-stable; [
              python39
              poetry
              python39.pkgs.pip
            ];
            shellHook = ''
              poetry env use ${pkgs.python39}/bin/python
              eval $(poetry env activate)
              echo "Python 3.9 environment activated"              
            '';
          };

          # Python 3.11 environment
          python311-dev = pkgs.mkShell {
            buildInputs = with pkgs; [
              python311
              poetry
              python311.pkgs.pip
            ];
            shellHook = ''
              poetry env use ${pkgs.python311}/bin/python
              eval $(poetry env activate)
              echo "Python 3.11 environment activated"
            '';
          };

          # Python 3.13 environment
          python313-dev = pkgs.mkShell {
            buildInputs = with pkgs; [
              python313
              python313.pkgs.pip
              poetry
            ];
            shellHook = ''
              poetry env use ${pkgs.python313}/bin/python
              eval $(poetry env activate)
              echo "Python 3.13 environment activated"
            '';
          };
          # # need to set this up for flutter
          # nix shell --impure nixpkgs#flutter nixpkgs#cocoapods nixpkgs#jdk17 -c $SHELL
        };
      });
}
