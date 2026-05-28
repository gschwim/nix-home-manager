# DevShells Modernization Plan

## Context

The `nix-home-manager` repository has completed its major 2026 modernization on the `master` branch (after the clean grok-1 → master merge). The current state includes:

- Stable channel pinning (`nixpkgs-25.11` + `home-manager/release-25.11` for Linux; the final `nixpkgs-26.05-darwin` + matching home-manager for Intel macOS)
- Fully user-agnostic design via the `mkHome` helper (any username works; homeDirectory derived by OS)
- Clean `targets/` (reusable profiles: linux, linux-desktop, osx) + `hosts/` (real machines with overrides, e.g. pleiades.nix)
- Desktop vs headless separation with full CLI parity for networking and system engineering tools
- `direnv` + `nix-direnv` already enabled with zsh integration in the base CLI profile (`modules/cli/programs.nix`)
- Rich existing shell/git/tmux/fzf/eza/etc. investment preserved
- `poetry` and `python3` already provided globally via `home.packages`

One major area of legacy technical debt remains unaddressed: the development shell (devshell) story.

The `devshells/flake.nix` is broken (references a commented-out `nixpkgs-stable` input, uses outdated Python versions and fragile `poetry env use` + `eval $(poetry env activate)` shell hooks). Legacy wrapper scripts in `modules/cli/packages.nix` (`python39-dev`, `python311-dev`, `python313-dev`) point to a non-existent external `~/environments/python` flake. The README correctly flags this as deferred work.

The user is a Python developer who primarily uses **Poetry** and does **not** want to adopt full Nix-based Python packaging (poetry2nix etc.) because those approaches do not port cleanly to other machines. They need a practical, maintainable path for pre-defined dev environments.

## User Requirements (Explicit)

1. Pre-defined, launchable environments for Python (Poetry-centric), Rust, and other languages.
2. Launch on demand via `nix develop .#name` or `nix shell .#name`.
3. Direnv auto-loading support (the foundation is already present).
4. **Poetry first by default**: Provide thin shells that supply a good Python + Poetry + native build tools environment and let Poetry manage its own `pyproject.toml` / lockfile / venvs. Do **not** force poetry2nix or equivalent unless the user explicitly opts in later.
5. A reliable "global" / ad-hoc Python experience (with `pip` + Jupyter notebooks) that works from any directory without requiring special project directories.
6. Clear options with pros/cons and a decision framework so the user can choose their preferred workflow with eyes open.

## Current State Problems

- `devshells/flake.nix` + `flake.lock` are broken and unmaintained.
- Legacy `python*-dev` wrapper scripts in `modules/cli/packages.nix` (lines 19-27) point to a dead path.
- No `devShells` outputs in the main `flake.nix` (the excellent pinned inputs are not yet leveraged for dev environments).
- No documented `.envrc` patterns or direnv examples for the repo.
- No story or offering for a "global Python + Jupyter" use case.
- Python versions in the old devshells flake are outdated relative to the current 25.11 / 26.05-darwin pins.
- The global `poetry` + `python3` in the Home Manager profile are useful but provide no isolation or reproducibility for specific projects or ad-hoc work.

## Options Analysis

### Option A: Keep separate `devshells/` flake (minimal change)
- Keep `devshells/flake.nix` as a standalone flake.
- Fix it, modernize Python versions, add Rust + other languages.
- Provide `.envrc` examples that use `use flake ../devshells#python313-dev`.
- Pros: Simple, isolated, easy for the user to understand.
- Cons: Two flakes to manage; less "one repo" experience; direnv paths become relative and fragile.

### Option B: Consolidate devShells into the main flake (recommended, with modular structure)
- Define the devShells in a separate, importable Nix file under `devshells/` (e.g. `devshells/default.nix` or `devshells/shells.nix` that exports an attrset of shells per system).
- The root `flake.nix` simply imports that module and wires the result into its `devShells` outputs.
- Use the existing pinned `nixpkgs-25-11` (and 26.05-darwin) inputs for reproducibility.
- Provide well-named project shells: `python312-poetry`, `python313-poetry`, `rust-stable`, etc.
- Pros: Single flake for the "one repo" experience + consistent pinning; keeps the root `flake.nix` small and clean (same modular philosophy as `targets/` / `hosts/` / `modules/`); easy direnv usage (`use flake .#python313-poetry`); trivial to review or extend the shells without touching the main flake.
- Cons: One extra file to maintain (very small price).

**Answer to "can we import as a module?"**: Yes. This is the recommended approach and matches the spirit of the rest of the repository.

### Option C: Hybrid (Poetry-first with optional nix2poetry)
- Provide "thin" devShells that give a clean Python + Poetry + native build tools (respecting Poetry's own lockfile and resolver).
- Offer an optional `poetry2nix`-based fully reproducible shell for projects that want it (documented path only; not included by default).
- Pros: Low friction for Poetry users (the primary audience) + clear power-user path available when desired.
- Cons: Two mental models (but the poetry2nix one is explicitly opt-in and secondary).

### The "Global Python" / Daily Driver Story (cross-cutting – major clarification)

The user's primary "global Python" for daily general-purpose CLI work is **the Python toolchain that is always present in the normal home-manager-managed environment** (i.e. after a regular `home-manager switch`).

- This is the equivalent of the old pyenv "global" python: always in PATH for normal terminals, scripts, ad-hoc work, Jupyter notebooks started outside any project, etc.
- When the user enters a project devShell (`nix develop .#python313-poetry` or via direnv), the devShell's Python + tools take precedence for that session (exactly like activating a venv or `pyenv shell`).
- The user wants to be able to "toss and start fresh" or point the daily global at a different version easily (via virtualenvs or future profile-level mechanisms).
- The `nix develop` shells we are adding are **project / task specific environments**, not the daily global.

Implication for this work:
- We will **not** create a primary `global-python` devShell as the user's daily driver.
- The daily global experience is owned by the CLI profile (`modules/cli/packages.nix` + any light curation we do there). We will document how it coexists with the new project devShells and how to get pyenv-like flexibility (venvs, multiple installed Pythons from the pin, easy "nuke and reset").
- We may still provide one or two small convenience ad-hoc shells (e.g. `python-adhoc` or just rely on the project shells + the profile global) if they add clear value; this will be decided with the user.

This directly replaces the earlier "dedicated global-python devShell for ad-hoc everywhere" idea with the user's actual mental model.

## Recommended Approach

**Option B (Consolidate into main flake) + Option C (Poetry-first + optional full reproducibility)**, with a strong "global Python" offering.

Rationale:
- Matches the user's desire for simplicity and Poetry compatibility.
- Gives a clean "one repo" experience while keeping the root flake small via an importable `devshells/` module.
- Provides clear on-ramps (simple Poetry-first project shells) and off-ramps (poetry2nix documented but not default).
- Direnv works naturally with `use flake .#<shell-name>`.
- The daily global Python story is clarified as the normal CLI profile (with pyenv-like flexibility documented), while the new devShells are strictly the project-specific layer that overrides it when active.

Implementation will target `master` (or a short-lived feature branch off `master` for the changes, followed by merge). The heavy lifting of the 2026 modernization (pinned inputs, targets/hosts split, direnv foundation) is already complete on master.

### Scope Inclusions
- Modern, working project devShells for Python (Poetry-focused) + at least one other language (Rust) as a proof of concept.
- Proper direnv `.envrc` examples and documentation.
- Clear separation + documentation of the "daily global" Python (the normal CLI profile experience, with pyenv-like flexibility) vs. the project devShells that override it when active.
- Removal of the legacy wrapper scripts in `modules/cli/packages.nix` (the three `python*-dev` `writeShellScriptBin` entries at lines 19-27).
- Complete deletion of the old standalone `devshells/flake.nix` + `flake.lock` (full rewrite / toss-out approved by user).
- Clear documentation in README explaining the options and decision points.
- Archiving of this approved plan as `devshells/PLAN.md` inside the repository.
- The devShell definitions themselves live in a clean, importable module under `devshells/`.

### Scope Exclusions (for this iteration)
- Full migration of every possible language/environment.
- Deep poetry2nix usage across many projects (provide the pattern, not the full migration).
- Changes to the user's Poetry workflow unless they explicitly choose the more reproducible path later.

## Key Decisions & Rationale

1. **Consolidate into main flake** rather than keeping a separate `devshells/` flake. This matches the earlier "one repo = one `nix develop` experience" goal and reduces cognitive load.

2. **Poetry-first shells by default**. Provide clean `python313-poetry` etc. shells that give a good Python + Poetry + tools environment without forcing `poetry2nix`. Offer `poetry2nix`-based shells as an explicit opt-in for projects that want full reproducibility.

3. **Daily global Python is the CLI profile** (not a devShell). The new devShells are strictly for project-specific work and layer on top of (override) the always-present daily global when active. Document the pyenv-like mental model, how to get flexibility ("toss and start fresh", venvs, multiple versions), and the clean coexistence story.

4. **Direnv as first-class citizen**. Provide ready-to-use `.envrc` snippets in the README.

5. **Remove legacy wrappers**. The `python*-dev` scripts pointing to `~/environments/python` will be removed (they are dead).

## Critical Files to Modify / Create

- `flake.nix` — Wire in the devShells by importing a new module (e.g. `import ./devshells/default.nix { inherit nixpkgs-25-11 nixpkgs-26-05-darwin; }`). Keep the root flake minimal.
- `devshells/` (new structure, per user preference "one file per devshell"):
  - `python312-poetry.nix`, `python313-poetry.nix`, `rust-stable.nix`, ... (individual, focused definitions)
  - `default.nix` (thin composer: imports the per-shell files, receives the pinned nixpkgs inputs, assembles and exports the final per-system attrsets for the root flake)
- This keeps every shell definition isolated and easy to review while still allowing a single clean import from `flake.nix`.
- `modules/cli/packages.nix` — Remove the dead `python39-dev` / `python311-dev` / `python313-dev` wrapper scripts (lines 19-27) and the associated comment. (Light curation of the "daily global" Python tools that live in the normal CLI profile can happen here if desired.)
- `devshells/flake.nix` + `devshells/flake.lock` — **Delete completely** (user explicitly approved a full rewrite / toss-out of the old devshells).
- `README.md` — Add a substantial new "Development Environments" section (after the existing "Default Shell" section). Cover:
  - The two layers (always-on CLI "global" Python from the home profile vs. project-specific devShells)
  - How to launch project shells on demand + direnv examples
  - The pyenv-like mental model migration for the daily global
  - Poetry-first notes + the documented (but not default) poetry2nix path
  - Decision framework
  Also update the "Deferred Work (TODOs)" list and the repo structure diagram.
- `devshells/PLAN.md` — New file: the final approved version of this plan (copied in during implementation) for long-term reference inside the repo.
- `devshells/README.md` (lightweight) — "Project devShells are defined in `default.nix` and wired from the root flake. The daily global Python lives in the CLI profile. See the Development Environments section in the main README and this PLAN.md."

## Existing Code & Patterns to Reuse

- Existing `direnv` + `nix-direnv` setup in `programs.nix` (the foundation for auto-loading the new project devShells).
- The pinned `nixpkgs-25-11` and `nixpkgs-26-05-darwin` inputs (for reproducible shells – passed into the new devshells module).
- The `mkShell` pattern from nixpkgs.
- The overall modular structure of the repo (`targets/`, `hosts/`, `modules/cli/`) – we will follow the same pattern for `devshells/default.nix`.
- The already-installed `poetry` + `python3` (and related tools) in the CLI profile as the starting point for the documented "daily global" Python experience.

## Detailed Work Items (Suggested Order)

1. **Inventory & Cleanup**
   - Remove the three legacy `python*-dev` wrapper scripts and comment from `modules/cli/packages.nix:19-27`.
   - (After validation) Delete `devshells/flake.nix` and `devshells/flake.lock` (or archive them).

2. **Design & Implement Core Shells (as importable module)**
   - Create `devshells/default.nix` (or `devshells/shells.nix`) that exports the shell attrsets for each supported system.
   - Wire it from the root `flake.nix` via a simple import (no logic lives in the root).
   - Define (at minimum) using the existing pinned inputs:
     - `python312-poetry` and `python313-poetry` (thin Poetry-first shells with sensible native build deps: stdenv.cc, pkg-config, openssl, etc.)
     - `rust-stable` (as a multi-language proof-of-concept: rustc, cargo, rust-analyzer, clippy, etc.)
     - (Optional, small) one or two convenience ad-hoc Python shells if they provide clear value beyond the profile global + the Poetry project shells.
   - Keep shellHooks minimal and non-brittle. Document normal Poetry usage (`poetry install`, `poetry run`, manual venv activation) plus any quality-of-life conveniences.
   - Explicitly support the two arches: `x86_64-linux` (25.11 pin) and `x86_64-darwin` (26.05-darwin pin).

3. **Direnv Documentation & Examples**
   - Add ready-to-copy `.envrc` snippets in the new README section.
   - Cover project use: `use flake /absolute/path/to/nix-home-manager#python313-poetry` (or relative equivalents when convenient).
   - Emphasize that `nix-direnv` (already enabled at `modules/cli/programs.nix:232`) provides excellent caching and works the same on Linux and macOS.

4. **Daily Global Python + Coexistence Documentation (the pyenv mental model)**
   - Clearly explain the two layers in the new README section:
     - Daily global / general-purpose Python lives in the normal CLI profile (the tools you get after a plain `home-manager switch`). This is the "always there" set for ad-hoc work, notebooks started from anywhere, etc.
     - Project-specific isolated environments come from the new devShells (override when active, exactly like a venv or `pyenv shell`).
   - Document how the user can get pyenv-like flexibility for the daily global (multiple Pythons from the pin, easy `python -m venv` usage, "nuke and reset" patterns, pointing at different versions when desired).
   - Explain clean coexistence: normal terminals use the profile global; `cd` into a Poetry project with a proper `.envrc` → devShell Python takes over for that session.

5. **Documentation & Decision Framework**
   - Write a clear "Development Environments" section in README.md (new primary user-facing docs).
   - Present the thin Poetry shells as the recommended default path for projects, with a clear "when you might later want poetry2nix" note.
   - Document the daily global Python (profile) vs. project devShells layering + the pyenv-like flexibility story.
   - Update the repo structure diagram and the "Deferred Work (TODOs)" list (mark this item complete and point to `devshells/PLAN.md`).

6. **Archival**
   - Write the final approved version of this plan to `devshells/PLAN.md` in the repo (and the short `devshells/README.md` pointer).

7. **Verification**
   - `nix flake check` passes with no new breakage.
   - `nix develop .#python313-poetry` and `.#rust-stable` succeed on both Linux (linux-x86 / pleiades) and Intel macOS (osx-intel).
   - Direnv loads the project shells correctly in test directories.
   - `home-manager switch` for existing configs is unaffected, the old wrapper binaries are gone from PATH, and the daily global Python tools remain available in normal shells.
   - `nix eval --json .#devShells --apply builtins.attrNames` shows the expected project shells.

## Verification Section

- `nix flake check` succeeds.
- All defined project devShells can be entered without error on `x86_64-linux` and `x86_64-darwin`.
- Direnv examples in the README are accurate (tested by implementer on at least one platform).
- The daily global Python (from the CLI profile) + project devShell layering is clearly documented, and the pyenv-like "toss / switch / venv" flexibility story is explained.
- Legacy wrapper scripts are removed; the old `devshells/` flake is **deleted** (full rewrite approved by user).
- Existing `homeConfigurations` (linux-x86, linux-x86-desktop, pleiades, darwin-intel, osx-intel) continue to evaluate and build cleanly.
- After a normal switch, the daily global Python tools are still present and usable in ordinary terminals (outside any devShell).

## Open Questions / Risks (to resolve with user before or during implementation)

- Exact Python versions for the first cut: recommend `python312-poetry` + `python313-poetry`. Drop 3.9 and 3.11 unless requested?
- Include a `rust-stable` shell in v1 (low cost, good signal for future languages)?
- poetry2nix: Provide one small example shell on day one (e.g. `python313-poetry2nix-demo`), or only document the pattern and add it later as an opt-in? (User is explicitly "ok with having a path... but not by default.")
- Do we still want any small ad-hoc convenience devShells (e.g. a minimal `python-adhoc` using the latest from the pin), or is the combination of (daily profile global + the Poetry project shells) sufficient?
- Daily global Python curation: Should this work include any light expansion/curations of the Python-related tools that live in the normal CLI profile (`modules/cli/packages.nix`), or is the current `python3` + `poetry` (plus whatever the user already has) good enough as the documented daily driver?
- Any preference on adding `flake-utils` as a new top-level input purely to simplify the devShells `eachSystem` logic inside `devshells/default.nix`, or keep everything explicit for the two supported arches?
- How opinionated should the daily global Python story be around "easy to toss and start fresh" (e.g. just docs + venvs, or also some helper scripts / aliases)?

## Risks & Mitigations

- Poetry + Nix friction / venv confusion: Mitigated by keeping shells thin + writing excellent, copy-pasteable examples that show both `poetry run` and manual activation paths.
- Different Python patch versions across the two pins (25.11 vs 26.05-darwin): Expected and acceptable (user already lives with this for the home configs).
- Native extension build deps (numpy, etc.): Include `stdenv.cc` + common `pkg-config` / `openssl` etc. in the Poetry shells; document per-project additions when needed.
- User expectation that "nix develop" will replace Poetry: The plan and docs will repeatedly emphasize that these are convenience shells that let Poetry continue to do what it does best.

## Archival & Reference (Implementation Step)

As an explicit part of this work (and per the user's request that the session plan location "is dumb" and it should live in the repo):

- The final reviewed + approved version of this plan will be written to `devshells/PLAN.md` at the root of the repository.
- A lightweight `devshells/README.md` will point users at the real implementation (root flake) and the plan.
- This ensures design decisions, options considered, rationale, and the "clear path to decide" are versioned alongside the code forever.

---

**Post-Implementation Cleanup**

- Update the "Deferred Work (TODOs)" bullet in README.md to read something like: "Python / language devshells – **Completed**. See `devshells/PLAN.md` and the new 'Development Environments' section in this README for usage and rationale."
- Remove or heavily comment the old devshells/ directory contents.
- Consider (future, low priority) adding Nix `templates` for "new Poetry project with direnv pre-wired to these shells."

---

**Status**: Fresh, focused DevShells Modernization Plan (post-merge). All obsolete merge content removed. Ready for review and approval via `exit_plan_mode`.
