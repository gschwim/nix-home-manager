{ config, pkgs, ... }:
{
  home.packages = [
    pkgs.hello
    pkgs.mtr-gui
  ];

}
