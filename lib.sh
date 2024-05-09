#!/bin/sh

readonly ESC='\033[0m'
readonly BOLD='\033[1m'
readonly BLUE='\033[34m'
readonly BLUE_UL='\033[4;34m'
readonly GREEN='\033[32m'
readonly GREEN_UL='\033[4;32m'
readonly RED='\033[31m'
readonly RED_UL='\033[4;31m'

clean_old() {
	# cleaning everything that is not a home-manager install
	echo "Cleaning old config things..."

	rm -rf ~/.nix*
	
	if [[ -e ~/.oh-my-zsh ]]; then
		rm -rf ~/.oh-my-zsh
	fi

	if [[ -e ~/.zshrc ]]; then
		rm ~/.zshrc
		rm ~/.zprofile
		rm ~/.zenv
		touch ~/.zshrc
	fi
}

prepare_or_update_debs() {
	echo "Updating OS with the necessaries..."
	sudo apt update
	sudo apt install --yes zsh wget ripgrep bat git curl fuse \
		build-essential gcc make unzip \
		gdb lcov pkg-config \
		libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
		libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
		lzma lzma-dev tk-dev uuid-dev zlib1g-dev
}

prepare_or_update_osx() {
	# Do I even need this?
	# brew install wget
	echo "Nix has taken over. No brew packages to install."
}

set_shell() {
	if [[ $(echo $SHELL | rev | cut -d "/" -f 1 | rev) != 'zsh' ]]; then
		echo "Updating shell..."
		sudo chsh -s `which zsh` $USER
	else
		echo "Shell already set properly."
	fi
}

install_nix() {
	# install nix and home-manager
	if command -v nix-store &> /dev/null; then
		echo "nix already installed. Skipping"
		return
	fi

	if [[ `uname` == "Darwin" ]]; then
		echo "TODO - installer for OSX"
		return
	fi

	echo "Installing nix..."
	sh <(curl -L https://nixos.org/nix/install) --daemon --yes

	 . $HOME/.nix-profile/etc/profile.d/nix.sh

}

configure_home_manager() {
	# install the home-manager config
	echo "Installing home-manager..."
	zsh -c "source /etc/zshrc && \
		nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager && \
		nix-channel --update"

	nix-shell '<home-manager>' -A install

	echo "Configuring home-manager"
	if [ ! -e ~/src/nix-home-manager ]; then
		mkdir -p ~/src/nix-home-manager
		git clone https://github.com/gschwim/nix-home-manager ~/src/nix-home-manager
	else
		echo "Found existing config. Updating..."
		zsh -c "cd ~/src/nix-home-manager && git pull && exit"
	fi

	rm -rf ~/.config/home-manager
	ln -s ~/src/nix-home-manager ~/.config/home-manager

	home-manager switch
}

install_or_update_dotfiles_nvim() {
	if [ ! -e ~/.config/nvim/.git ]; then
		echo "Clear any old nvim stuff..."
		rm -rf ~/.config/nvim
		rm -rf ~/.local/share/nvim
		echo "Install nvim config..."
		git clone https://github.com/gschwim/dotfiles.nvim.git ~/.config/nvim/
	else
		echo "Updating nvim config..."
		zsh -c "cd ~/.config/nvim && git pull && exit"
	fi

}

install_or_update_pyenv() {
	if [[ -e ~/.pyenv ]]; then 
		echo "pyenv already installed. Updating..."
		zsh -c "cd ~/.pyenv && git pull && \
			cd ~/.pyenv/plugins/pyenv-virtualenv && git pull && \
			exit"
	else
		echo "Installing pyenv..."
		git clone https://github.com/pyenv/pyenv.git ~/.pyenv
		git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
	fi
}

install_wezterm_config() {
	echo "Installing wezterm config"
	echo "NOTE: Wezterm install will need to be manually"
	cp ~/src/nix-home-manager/wezterm.lua ~/.wezterm.lua
}

textout() {
    echo "$1"
    shift
    if [ "$*" = "" ]; then
        cat
    else
        echo "$@"
    fi
    echo "$ESC"
}

ui_confirm() {
    textout "$GREEN$GREEN_UL" "$1"

    local prompt="[y/n] "
    echo -n "$prompt"
    while read -r y; do
        if [ "$y" = "y" ]; then
            echo ""
            return 0
        elif [ "$y" = "n" ]; then
            echo ""
            return 1
        else
            textout "$RED" "Sorry, I didn't understand. I can only understand answers of y or n"
            echo -n "$prompt"
        fi
    done
    echo ""
    return 1
}

install_system() {

	# clean out old things
	clean_old

	if [[ $step == 1 ]]; then
		keep_going
	fi

	# prepare and/or update the os
	if [[ `uname` == "Linux" ]]; then
		prepare_or_update_debs
	elif [[ `uname` == "Darwin" ]]; then
		prepare_or_update_osx
	else
		echo "Unknown OS. Stopping!"
		return
	fi

	# set the shell to zsh
	set_shell

	if [[ $step == 1 ]]; then
		keep_going
	fi

	# install nix and home-manager
	install_nix

	if [[ $step == 1 ]]; then
		keep_going
	fi
}

install_user() {
	# configure home-manager
	configure_home_manager

	if [[ $step == 1 ]]; then
		keep_going
	fi

	# install neovim config
	install_or_update_dotfiles_nvim

	if [[ $step == 1 ]]; then
		keep_going
	fi

	# install pyenv
	install_or_update_pyenv

	if [[ $step == 1 ]]; then
		keep_going
	fi

	# install wezterm config
	install_wezterm_config
}
