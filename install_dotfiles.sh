#!/bin/bash

export WORKDIR=$(pwd)

## establish some necessary directories
if [ ! -e ~/.local/bin ]; then
	echo "Creating ~/.local/bin"
	mkdir -p ~/.local/bin
fi

## Install os dependencies, upgrade them, and add os-specific installs
echo "Installing zsh and friends..."
if [[ `uname` == "Linux" ]] ; then
	sudo apt update
	sudo apt install --yes zsh wget ripgrep bat git curl fuse \
		build-essential gcc make unzip \
		gdb lcov pkg-config \
		libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
		libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
		lzma lzma-dev tk-dev uuid-dev zlib1g-dev

	wget -O ~/.local/bin/nvim https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
	chmod +x ~/.local/bin/nvim
	
	## install exa, the replacement for 'ls'
	echo "Installing exa, the replacement for 'ls'..."
	wget -O /tmp/exa.zip https://github.com/ogham/exa/releases/download/v0.10.0/exa-linux-x86_64-v0.10.0.zip
	unzip /tmp/exa.zip -d ~/.local/

	## install dust, the replacement for 'du'
	echo "Installing dust, the replacement for 'du'..."
	wget -O /tmp/dust.deb https://github.com/bootandy/dust/releases/download/v0.8.5/du-dust_0.8.5_amd64.deb
	sudo dpkg -i /tmp/dust.deb

elif [[ `uname` == "Darwin" ]] ; then
	brew install wget ripgrep bat exa dust neovim
fi


## neovim!
if [ ! -e ~/.config/nvim/.git ]; then
	echo "Clear any old nvim stuff..."
	rm -rf ~/.config/nvim
	rm -rf ~/.local/share/nvim
	echo "Install nvim config..."
	git clone https://github.com/gschwim/dotfiles.nvim.git ~/.config/nvim/
else
	echo "Updating nvim config..."
	bash -c "cd ~/.config/nvim && git pull && exit"
fi

## Oh my zsh!
export ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
cp zshrc ~/.zshrc
if [ ! -e ~/.zshrc_local ]; then
	echo "Creating ~/.zshrc_local"
	cp zshrc_local ~/.zshrc_local
fi

cp zprofile ~/.zprofile
cp zshenv ~/.zshenv

if test -e ~/.oh-my-zsh; then
	echo "Oh-My-Zsh already installed. Updating..."
	zsh -c "source ~/.zshrc; omz update"	
	echo "Updating spaceship prompt..."
	cd $ZSH_CUSTOM/themes/spaceship-prompt
	git pull
	cd $WORKDIR
else
	echo "Installing Oh-My-Zsh..."
	wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O /tmp/omz_install.sh
	chmod +x /tmp/omz_install.sh
	/tmp/omz_install.sh --unattended --keep-zshrc
	echo 'Installing spaceship prompt'
	git clone -v https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
	ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
fi
wait

## install starship
echo "Installing Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin --yes 
cp starship.toml ~/.config/
wait

## install pyenv
if test -e ~/.pyenv; then 
	echo "pyenv already installed. Updating..."
	cd ~/.pyenv
	git pull
	# zsh -c "source ~/.zshrc; echo $(pyenv root); cd $(pyenv root); git pull"
	cd $WORKDIR
else
	echo "Installing pyenv..."
	git clone https://github.com/pyenv/pyenv.git ~/.pyenv
	git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv

fi
wait

# ## install rust things
# if [ ! -e ~/.cargo ]; then
# 	echo "Installing Rust"
# 	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# fi
#
# wait
# source ~/.cargo/env

## change shell if needed
if [[ `uname` == "Linux" ]]; then
	if [[ $(echo $SHELL | rev | cut -d "/" -f 1 | rev) != 'zsh' ]]; then
		echo "Updating shell. Too lazy to make this smarter right now..."
		sudo chsh --shell /usr/bin/zsh $USER
	fi
fi


## tmux config
cp tmux.conf ~/.tmux.conf

## wezterm config
cp wezterm.lua ~/.wezterm.lua

## Go!
zsh
