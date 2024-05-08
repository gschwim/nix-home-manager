###### run the workflow

export step=0

print "WARNING: This will render any existing environment destroyed!"
vared -p "Install the environment? (Y/y to proceed): " -c proceed

if [[ ! ${proceed:l} =~ "y" ]]; then
	print "Quitting install." 
	return
fi

# prepare and/or update the osl
print "Beginning the install..."

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
		print "Unknown OS. Stopping!"
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
