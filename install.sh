# import the lib.sh stuff
. ./lib.sh

export step=0

textout "$RED$RED_UL" "WARNING: This will render any existing environment destroyed!"
if ! ui_confirm "Install the environment? (Y/y to proceed): "; then
	echo "$RED$RED_UL" "Quitting install!"
	return 0

fi


# prepare and/or update the osl
echo "$BLUE" "Beginning the install..."


