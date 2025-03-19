{
  description = "Global Python development environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells = {
          # Python 3.9 environment
          python39-dev = pkgs.mkShell {
            buildInputs = with pkgs; [
              python39
              poetry
              python39.pkgs.pip
            ];
            shellHook = ''
              export PYTHONPATH=""
              export PATH="$PWD/.venv/bin:${pkgs.python39.pkgs.pip}/bin:$PATH"
              if [ ! -d .venv ]; then
                poetry env use ${pkgs.python39}/bin/python
              fi
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
              export PYTHONPATH=""
              export PATH="$PWD/.venv/bin:${pkgs.python311.pkgs.pip}/bin:$PATH"
              if [ ! -d .venv ]; then
                poetry env use ${pkgs.python311}/bin/python
              fi
              echo "Python 3.11 environment activated"
            '';
          };

          # Python 3.13 environment
          python313-dev = pkgs.mkShell {
            buildInputs = with pkgs; [
              python313
              poetry
              python313.pkgs.pip
            ];
            shellHook = ''
              export PYTHONPATH=""
              export PATH="$PWD/.venv/bin:${pkgs.python313.pkgs.pip}/bin:$PATH"
              if [ ! -d .venv ]; then
                poetry env use ${pkgs.python313}/bin/python
              fi
              echo "Python 3.13 environment activated"
            '';
          };
        };
      });
}
