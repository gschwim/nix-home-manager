# devshells/

Project-specific development environments for this repo.

These are **not** the daily global Python you get from a normal `home-manager switch`.
They are isolated, reproducible shells for specific projects or tasks (Poetry, Rust, etc.).

See the "Development Environments" section in the root [README.md](../README.md) for usage, the pyenv-like mental model for the daily global, direnv examples, and the decision framework (Poetry-first by default, poetry2nix as opt-in path only).

## Layout (one file per devshell)

- `python312-poetry.nix`
- `python313-poetry.nix`
- `rust-stable.nix`
- `default.nix` — thin composer that imports the above and exports the final per-system attrsets

The root `flake.nix` wires them with a single import.

## Adding a new devshell

1. Create `new-thing.nix` exporting `pkgs: pkgs.mkShell { ... }`
2. Import it in `default.nix`
3. Add it to the `mkShellsFor` attrset
4. Document it in the main README
5. (Recommended) Add a short alias like `alias devfoo='dev the-new-shell'` in the zsh `initContent` in `modules/cli/programs.nix` so everyone gets the same nice `devfoo` experience after switching.

## Ergonomics (no long paths + your normal shell)

After deploying this config you automatically get:

- `py313`, `py312`, `devrust` (and the generic `dev <name>` function) from any terminal.
- One-time per machine: `nix registry add nix-home-manager /path/to/checkout` → then `nix develop nix-home-manager#...` and `use flake nix-home-manager#...` in direnv work with short names everywhere.

When you enter any devShell (via `py313`, `nix develop`, or direnv), you are now automatically dropped into **your normal customized zsh** (with starship, aliases, fzf, zoxide, plugins, etc.) instead of a plain bash.

See the main README "Development Environments" section for full details.

## Archived design

The full approved plan that produced this structure lives at `PLAN.md` in this directory.
