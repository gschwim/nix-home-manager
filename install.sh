# import the lib.sh stuff
. ./lib.sh

export step=0

# handle the command line flags
INSTALL_MODE=none_selected
print_help()
        {
            echo "GS Nix Environment Installer [--all] [--user] [--system]"

            echo "Choose only one installation method and the confirm option only."
            echo ""
            echo " --all:       Installs both the system daemon and user components for the current user."
            echo ""
            echo " --user:      Installs the user components only. Useless without the system parts installed."
            echo ""
            echo " --system:    Installs the system components only, leaving the user environment (mostly) intact."
            echo ""
            echo " --yes:       Confirm to proceed without asking."
            echo ""
} >&2

if [ $# -le 2 ]; then
    while [ $# -gt 0 ]; do
        case $1 in
            --all)
                INSTALL_MODE=all;;
            --user)
                INSTALL_MODE=user;;
            --system)
                INSTALL_MODE=system;;
            --yes)
                CONFIRMED=yes;;
            *)
                print_help
                exit;;
        esac
        shift
    done
fi

if [ "$INSTALL_MODE" = "none_selected" ]; then
    echo "$RED$RED_UL" "Must select an install option to proceed!"
    echo "$ESC"
    print_help
    exit
fi


#############################################

if ! [ "$CONFIRMED" = "yes" ]; then
    textout "$RED$RED_UL" "WARNING: This will render any existing environment destroyed!"
    textout "$RED$RED_UL" "You selected install option = $INSTALL_MODE."
    if ! ui_confirm "Install the environment? (Y/y to proceed): "; then
            echo "$RED$RED_UL" "Quitting install!"
            return 0

    fi
fi

# prepare and/or update the osl
echo "$BLUE" "Beginning the install..."

case $INSTALL_MODE in
    system)
        echo "Installing system components..."
        install_system;;
    user)
        echo "Installing user components..."
        install_user;;
    *)
        echo "Unknown install mode: $INSTALL_MODE"
esac

