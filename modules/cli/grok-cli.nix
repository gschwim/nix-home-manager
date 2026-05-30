{ config, pkgs, lib, llm-agents, ... }:

let
  # The grok package from llm-agents.nix is currently only available on Linux.
  # On Darwin we simply don't install it (the official curl|bash installer can
  # still be used manually on macOS if needed).
  hasGrok = builtins.hasAttr "grok" llm-agents.packages.${pkgs.system} or false;
in
{
  # xAI Grok Build CLI (official TUI coding agent)
  #
  # Installed declaratively using the community-maintained binary from
  # github:numtide/llm-agents.nix (instead of the official curl | bash script).
  #
  # On Linux this gives you the `grok` command with no manual PATH or shell
  # configuration changes.
  #
  # On Darwin the package is not yet exposed by the upstream flake, so we
  # skip installation (you can still use the official installer if desired).

  home.packages = lib.optional hasGrok llm-agents.packages.${pkgs.system}.grok;
}