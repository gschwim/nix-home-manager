# nix-home-manager

Personal Home Manager configuration using flakes. Designed to work cleanly across:

- macOS (Intel)
- Ubuntu Linux
- NixOS

## Current State (as of 2026)

- **Linux**: Pinned to `nixpkgs-25.11` + matching `home-manager/release-25.11`
- **Intel macOS**: Pinned to the final supported release (`nixpkgs-26.05-darwin` + `home-manager/release-26.05`)
- Fully user-agnostic: no hard-coded usernames. The same config works for any user on any supported machine.
- Core shell environment lives in `modules/cli/` (zsh + starship + tmux + fzf + git+delta + eza + bat + direnv + neovim + etc.)

## Usage

### On macOS (Intel)

```bash
cd ~/src/nix-home-manager

# Daily driver (includes extras from targets/osx.nix)
home-manager switch --flake .#osx-intel

# Minimal version
home-manager switch --flake .#darwin-intel
```

> **Note:** `bin/homectl` (and any new files referenced by `builtins.readFile` or relative paths inside `flake.nix`) must be tracked by git. Run `git add bin/homectl` (and `git commit` if you want a clean tree) before the first `home-manager switch --flake` or `nix run` after introducing/changing it. Otherwise Nix's flake source filtering will produce a `*-source` tree that lacks the file, leading to "opening file '/nix/store/...-source/bin/homectl': No such file or directory" during activation (the same class of error previously seen with the update checker script).

### On Linux (Ubuntu or NixOS)

```bash
cd ~/src/nix-home-manager

home-manager switch --flake .#linux-x86
```

Or, once deployed, use the `homectl` helper (installed into PATH and also available via `nix run`):

```bash
# Auto-detects target from /etc/nixos-host-info + hostname (or uname on darwin)
# and does the switch from the flake in NIX_HOME_MANAGER_CONFIGS_DIR.
homectl switch

# Show detected / current implemented target + flake info
homectl info

# List generations (wraps home-manager generations)
homectl generations
```

After a switch you may see various activation messages (font cache, bat cache rebuild, etc.). 

The "There are N unread and relevant news items. Read them by running `home-manager news`" notice is deliberately silenced in this flake setup (see `news.display = "silent";` in `home.nix`). Those news are primarily useful when following the Home Manager unstable channel with the classic `~/.config/home-manager/home.nix` layout. With pinned flake inputs they are rarely relevant.

If you do want to read the news for a target:

```bash
# Linux (25.11)
nix run home-manager/release-25.11 -- news --flake .#linux-x86

# macOS Intel (26.05)
nix run home-manager/release-26.05 -- news --flake .#osx-intel
```

The bare `home-manager news` command will not work (it looks for a legacy config file).

The configuration now works for **any username** without editing source files. When defining new machines, just pass the desired `username` in the flake.

## Repository Structure

```
flake.nix                 # Pins + homeConfigurations + mkHome helper
home.nix                  # Core settings (now receives username from the flake)
modules/cli/              # The actual configuration you care about
├── cli.nix
├── packages.nix
├── programs.nix
└── variables.nix         # Large git alias collection + starship config
targets/
├── linux.nix             # Base Linux target profile
├── linux-desktop.nix     # Linux + desktop environment target
└── osx.nix               # macOS target profile

hosts/
└── (real machine configs go here, e.g. pleiades.nix)
devshells/                # Project devShells (one file per shell). See "Development Environments" section.
```

## Making It Work for a Different User / Machine

Because everything is now parameterized:

1. In `flake.nix`, add or modify a `homeConfiguration` and supply the correct `username`.
2. Optionally import or extend a target from `targets/` (or a full host config from `hosts/`).
3. Run `home-manager switch --flake .#your-config`.

Example for a new Linux user "alice":

```nix
alice-laptop = mkHome {
  nixpkgs' = nixpkgs-25-11;
  home-manager' = home-manager-25-11;
  system = "x86_64-linux";
  username = "alice";
  modules = [ ./targets/linux.nix ];
};
```

## Default Shell

This configuration enables and heavily customizes Zsh for all profiles.

To make Zsh your actual default shell:

- **On NixOS** (recommended when using Home Manager as a module):  
  Set `users.users.<yourname>.shell = pkgs.zsh;` in your system configuration.

- **Standalone** (macOS, Ubuntu, or standalone on NixOS):  
  Run `chsh -s $(which zsh)` (or the full Nix store path).

We also set `SHELL` and configure Ghostty + Wezterm (on desktop profiles) to prefer Zsh.

## Environment Variables for Helper Scripts & Local Customizations

Home Manager sets the following variables pointing at your source checkouts (available in any shell it manages via `home.sessionVariables`):

- `NIX_HOME_MANAGER_CONFIGS_DIR` — the directory containing this home-manager configuration (`~/src/nix-home-manager`)
- `NIXOS_CONFIGS_DIR` — the directory containing your nixos-configs (`~/src/nixos-configs`)

`NIX_HOME_MANAGER_FLAKE` is also provided for the dev helpers (the short `py313` etc. aliases and `dev()` function) that use it as a flake reference.

For machine-local additions, overrides (including the variables above), or glue for helper scripts, use the generic local-only file:

```sh
[[ -f ~/.localrc ]] && source ~/.localrc
```

Home Manager seeds `~/.localrc` once during the first activation (it contains only a short header explaining that it is user-owned). After that the file is 100% yours — future `home-manager switch` runs will never modify or overwrite it. Source the same file at the end of your `.bashrc`, `config.fish`, or any other shell rc for consistent behavior across shells.

## Development Environments

This repo now provides **project-specific devShells** via `nix develop` / `nix shell` / direnv while preserving a reliable daily "global" Python experience in your normal CLI profile.

### The two-layer mental model (the key concept)

1. **Daily global Python** (your normal environment after `home-manager switch`)
   - Always in `$PATH` for ad-hoc work, quick scripts, Jupyter notebooks started from anywhere, one-off `python -c`, etc.
   - This is the spiritual successor to a pyenv "global" python.
   - You control it the same way you control your Home Manager profile: edit `modules/cli/packages.nix` (or add tools via the normal profile mechanisms) and re-switch.
   - "Toss and start fresh" is easy: `rm -rf ~/.cache/pypoetry/virtualenvs/*` (or the specific venv), use normal `python -m venv`, or simply re-switch after cleaning. No special global version manager required.

2. **Project devShells** (the new `nix develop` things)
   - Isolated, reproducible environments for a specific project or task.
   - Launched on demand: `nix develop .#python313-poetry`
   - When active (directly or via direnv), they take precedence over the daily global for that shell session — exactly like activating a venv or running `pyenv shell`.
   - Poetry-first by design: the shells give you a good Python + Poetry + native build tools; **Poetry itself** manages `pyproject.toml`, the lockfile, and venvs. We deliberately do **not** force poetry2nix (which does not port well).

When you are not inside a devShell, you are on the daily global. When you enter one, you get the project-isolated version. Clean, predictable, and matches how most Python developers already think.

### Currently available project devShells

| Shell                | Short alias (after switch) | What you get |
|----------------------|----------------------------|--------------|
| `python312-poetry`   | `py312`                    | Python 3.12 + Poetry + common tools |
| `python313-poetry`   | `py313`                    | Python 3.13 + Poetry + common tools (recommended) |
| `rust-stable`        | `devrust`                  | Modern Rust (rustc, cargo, rust-analyzer, clippy, rustfmt) |

You can always use the full form too: `dev python313-poetry` or (after registry) `nix develop nix-home-manager#python313-poetry`.

All are built from the same high-quality pinned nixpkgs inputs as your home configuration (25.11 for Linux, final 26.05-darwin for Intel macOS).

### Launching shells (no long paths needed)

After you run `home-manager switch`, your shell automatically gets these convenient helpers:

```bash
py313           # same as: nix develop ...#python313-poetry
py312           # python 3.12 + Poetry
devrust         # Rust stable

# Or the more explicit form (also always available)
dev python313-poetry
dev rust-stable --command cargo --version
```

These work from **any directory** on any machine where you've deployed this config. No need to remember or type the path to the repo.

**Even shorter (recommended one-time setup per machine):**

```bash
# Do this once on a machine (point it at wherever you keep the checkout)
nix registry add nix-home-manager "$HOME/src/nix-home-manager"

# Now you can use the short registered name everywhere:
nix develop nix-home-manager#python313-poetry
nix develop nix-home-manager#rust-stable
```

This is the cleanest way to completely eliminate long paths.

### Direnv auto-loading (the good way)

Once you have done the `nix registry add` step above on a machine, your `.envrc` files become beautifully short:

```bash
# .envrc  (in any project directory)
use flake nix-home-manager#python313-poetry
```

```bash
direnv allow
```

That's it. No absolute paths, no `../..` relative hacks, works on every machine after the one-time registry setup.

**If you prefer not to use the registry**, the shell helpers above still make interactive use painless, and for direnv you can use a stable symlink convention:

```bash
# One-time per machine
ln -sfn "$HOME/src/nix-home-manager" "$HOME/.config/nix-home-manager"

# Then in any .envrc
use flake ~/.config/nix-home-manager#python313-poetry
```

The helpers + registry (or symlink) combination removes the previous pain point of typing full repo paths constantly.

### Daily global Python flexibility (the pyenv-like part)

- The tools that are "just there" after a normal switch live in `modules/cli/packages.nix` (currently `python3` + `poetry` plus whatever else you have added over time).
- Need a different Python for a one-off task? Use a normal virtualenv or `python -m venv /tmp/experiment && source ...`
- Want to experiment with a completely clean slate? Delete the Poetry virtualenv cache or the specific project venvs and re-run `poetry install` inside the devShell (or outside it on the global).
- Multiple versions are available via the pinned nixpkgs; you can always add explicit `python311`, `python312`, etc. to your personal profile overrides if you want several "global candidates" visible at once.

This gives you the "set a global, toss it when needed, point at another via venv" workflow you liked from pyenv, but with fully reproducible pins and no extra version manager to maintain.

### Poetry notes

- These shells are intentionally **thin**. They do not try to manage your Python dependencies for you — Poetry does that.
- Inside a `python313-poetry` shell you run normal `poetry install`, `poetry run`, `poetry shell`, etc.
- Native wheels that need compilation (numpy, psycopg2, etc.) should just work because we include a C toolchain + pkg-config + openssl.
- If a project needs extra system libs, add them temporarily in your local shell or propose a small addition to that specific devshell file.

### When you might later want the poetry2nix path

Poetry2nix gives you fully declarative, Nix-managed Python dependencies (no Poetry lockfile or venv at all). It is more reproducible across machines but has a steeper learning curve and does not port to non-Nix machines.

We deliberately did **not** make it the default. A documented opt-in path exists if you ever have a project where the extra reproducibility is worth the trade-off. Ask if you want an example shell added.

### Adding a new devShell

See `devshells/README.md` (one file per shell + tiny composer, following your "one file per devshell" preference).

After adding one, also consider adding a short `alias devfoo='dev the-new-shell'` in the zsh `initContent` block (in `modules/cli/programs.nix`) so it gets the same ergonomic treatment everywhere you deploy.

## Personal Update Notifications (Maintainer Only)

A background checker for the maintainer's two personal repos (nix-home-manager and nixos-configs, both under ~/src) is included.

New mechanism (no shell background jobs):
- The `check-repo-updates` POSIX script lives in `~/.local/bin`.
- On Linux/NixOS (including headless/CLI-only): a systemd user timer (`check-nix-repos.timer`, hourly + Persistent + RandomizedDelay) + a oneshot on default.target runs the script for both repos externally. It does git fetch (or clone if dir missing on new systems) and writes status (commit count) to `$XDG_CACHE_HOME/repo-updates/*/status` (falls back to `~/.cache`).
- On macOS/Darwin: equivalent launchd user agent (`com.user.check-nix-repos`) with RunAtLoad + StartInterval=3600. Home Manager handles plist deployment to ~/Library/LaunchAgents and launchctl bootstrap.
- On other Linux (Ubuntu/Mint etc without systemd --user): see cron examples inside `modules/personal/update-checker.nix`.
- **Signal via Starship prompt**: A custom module shows "🔄HM" and/or "🔄NIX" (yellow) in the prompt if the corresponding status file exists. Completely passive and instant (just file test). Uses the same XDG-aware cache path as the script.
- Manual: `hm-check-updates` forces an immediate check (interval=0) and updates status (prompt indicator will appear on next prompt).
- Auto-clone: if the expected ~/src/... dir doesn't exist when checker runs, it clones the repo (with message).
- Vars: `NIX_HOME_MANAGER_FLAKE` and `NIXOS_CONFIGS_DIR` (in sessionVariables).
- The checker prefers the nixpkgs git from your profile (via PATH injection in the units) so there are no Xcode license prompts on macOS.
- Disable: remove the personal bits (see below). (There is no NIX_HM_UPDATE_CHECK_INTERVAL; the script always rate-limits internally.)

**This is personal-only for the maintainer's (gschwim) setup.** The implementation is isolated with prominent "PERSONAL-ONLY ... DELETE FOR FORKS" comments. If you forked this repo: delete the import of `modules/personal/update-checker.nix` from `home.nix`, the PERSONAL block near the end of zsh `initContent` in `modules/cli/programs.nix`, the custom Starship module in `variables.nix`, and this README section. You are on your own.

See:
- `modules/personal/check-repo-updates` (script)
- `modules/personal/update-checker.nix` (systemd units + launchd.agents + home.file + PATH injection + cron examples)
- PERSONAL block in `modules/cli/programs.nix`
- Starship custom in `modules/cli/variables.nix`

The previous shell-launched bg job approach has been removed. Checks happen via external scheduler (systemd/launchd); shells only read status files for the prompt signal.

## Deferred Work (TODOs)

- **NixOS (and Darwin) host target detection for home-manager deployment**: Implemented as `homectl` (in `bin/homectl`, exposed via flake apps/packages, installed into PATH). `homectl switch` deploys using auto-detected target from /etc/nixos-host-info (hostname first, then desktop_environment/role + OS) or uname/hostname fallback. Also provides `homectl info` and `homectl generations`. See the plan in the session notes + usage examples above. (The old generic "hm-deploy" description is superseded.)

- **Personal systemd user units for repo housekeeping** (the `check-nix-repos*` services/timer): These are best-effort oneshot units. The bare `systemctl --user status` command only shows a high-level summary of the user manager and typically only surfaces *failing* units. Healthy oneshot services and their timers do not appear there. Use `systemctl --user list-units | grep check-nix`, `systemctl --user status check-nix-repos.timer`, `systemctl --user list-timers`, and `journalctl --user -u check-nix-repos*` to inspect them. The units are deliberately made to always succeed (exit 0) so they never degrade the user session.
- **Bootstrap story**: The old `install` + `lib.sh` scripts are deprecated. A clean, modern way to bootstrap a brand new machine from scratch is a planned future improvement.
- **Pure Nix Neovim configuration (optional)**: The current Neovim setup sources the entire `dotfiles.nvim` repo via `xdg.configFile."nvim"`. A full conversion to declarative `programs.neovim` (plugins, treesitter grammars, etc.) is possible but would be significant effort because the config is built on lazy.nvim. This is tracked as an **optional low-priority future item**.
- **NixOS module integration**: Support using this configuration via Home Manager as a NixOS module (instead of standalone `home-manager switch`). This would allow managing system + user configuration together with a single `nixos-rebuild switch`.

Python / language devshells modernization is **complete** (see `devshells/PLAN.md` and the section above).

The legacy wrapper scripts have been removed and the old `devshells/` flake has been deleted.

## Grok Build CLI (xAI)

The official xAI Grok Build CLI (`grok` command) is installed declaratively for all hosts using the community-maintained package from `github:numtide/llm-agents.nix`.

After a `home-manager switch`, the `grok` command is available with no manual PATH changes required.

**Updating**
```bash
nix flake update llm-agents
home-manager switch --flake .#<your-host>
```

See `modules/cli/grok-cli.nix` for details and the future TODO list.

## Verification

After changes:

```bash
nix flake check
nix eval --json .#homeConfigurations --apply builtins.attrNames
```

## Notes

- `home.stateVersion` is set to `"25.11"` on the Linux side (matching the pin).
- The old `/home/schwim2` references and other machine-specific hardcoding have been removed.
- Most of the value is in the shared `modules/cli/` programs and aliases — those are intentionally left alone unless something is actually broken.

Contributions / extensions are welcome as long as they don't regress the multi-OS (macOS + Ubuntu + NixOS) and user-agnostic goals.
