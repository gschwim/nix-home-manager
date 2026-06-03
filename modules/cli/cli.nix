{ pkgs, ... }:
{
imports = [
  ./packages.nix
  ./programs.nix
  ./grok-cli.nix
  ]; 
}
