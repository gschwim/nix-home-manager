#!/bin/sh

# install nix and home-manager
echo Installing nix...
sh <(curl -L https://nixos.org/nix/install) --no-daemon

echo installing home-manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update

nix-shell '<home-manager>' -A install

# install the home-manager config
mkdir -p ~/src
cd src
git clone https://github.com/gschwim/nix-home-manager
cd ~/.config/home-manager
rm -rf home.nix
ln -s ~/src/nix-home-manager/home.nix home.nix

echo done for now
echo please log out and back in to complete the install

