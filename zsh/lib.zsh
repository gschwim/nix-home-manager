#!/bin/sh

clean_old() {
	# cleaning everything that is not a home-manager install
	print "Cleaning old config things..."

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
	print "Updating OS with the necessaries..."
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
	print "Nix has taken over. No brew packages to install."
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
		print "nix already installed. Skipping"
		return
	fi

	if [[ `uname` == "Darwin" ]]; then
		print "TODO - installer for OSX"
		return
	fi

	print "Installing nix..."
	sh <(curl -L https://nixos.org/nix/install) --daemon --yes

	 . $HOME/.nix-profile/etc/profile.d/nix.sh

	print "Installing home-manager..."
	echo installing home-manager
	nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
	nix-channel --update

	nix-shell '<home-manager>' -A install
}

configure_home_manager() {
	# install the home-manager config
	print "Configuring home-manager"
	if [ ! -e ~/src/nix-home-manager ]; then
		mkdir -p ~/src/nix-home-manager
		git clone https://github.com/gschwim/nix-home-manager ~/src/nix-home-manager
	else
		print "Found existing config. Updating..."
		zsh -c "cd ~/src/nix-home-manager && git pull && exit"
	fi

	rm -rf ~/.config/home-manager
	ln -s ~/src/nix-home-manager ~/.config/home-manager

	home-manager switch
}

install_or_update_dotfiles_nvim() {
	if [ ! -e ~/.config/nvim/.git ]; then
		print "Clear any old nvim stuff..."
		rm -rf ~/.config/nvim
		rm -rf ~/.local/share/nvim
		print "Install nvim config..."
		git clone https://github.com/gschwim/dotfiles.nvim.git ~/.config/nvim/
	else
		print "Updating nvim config..."
		zsh -c "cd ~/.config/nvim && git pull && exit"
	fi

}

install_or_update_pyenv() {
	if [[ -e ~/.pyenv ]]; then 
		print "pyenv already installed. Updating..."
		zsh -c "cd ~/.pyenv && git pull && \
			cd ~/.pyenv/plugins/pyenv-virtualenv && git pull && \
			exit"
	else
		print "Installing pyenv..."
		git clone https://github.com/pyenv/pyenv.git ~/.pyenv
		git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
	fi
}

install_wezterm_config() {
	print "Installing wezterm config"
	print "NOTE: Wezterm install will need to be manually"
	cp ~/src/nix-home-manager/wezterm.lua ~/.wezterm.lua
}

keep_going() {
	vared -p "Press any key to continue..." -c blah
}