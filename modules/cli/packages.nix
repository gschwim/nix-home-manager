{ pkgs, ... }:
{
  home.packages = [
    pkgs.dust
    pkgs.fd
    pkgs.tlrc
    pkgs.wget
    pkgs.curl
    pkgs.difftastic
    pkgs.python3
    pkgs.poetry
    pkgs.yt-dlp

    ### vget for video grabs
    (pkgs.writeShellScriptBin "vget" ''
      yt-dlp --cookies-from-browser chrome $*
    '')
    ### for dev environments flake
    (pkgs.writeShellScriptBin "python39-dev" ''
      nix develop ~/environments/python#python39-dev
    '')
    (pkgs.writeShellScriptBin "python311-dev" ''
      nix develop ~/environments/python#python311-dev
    '')
    (pkgs.writeShellScriptBin "python313-dev" ''
      nix develop ~/environments/python#python313-dev
    '')
  ];

}
