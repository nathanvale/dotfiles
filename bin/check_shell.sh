#!/bin/bash

# Ensure the script is being run from the correct directory
set -e  # Exit on error

cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

if [ "$SHELL" == "/bin/bash" ]; then
    "log $INFO ""Script is being run in bash."
elif [ "$SHELL" == "/bin/zsh" ]; then
    "log $INFO ""Script is being run in zsh."
else
    "log $ERROR ""This script must be run from a bash or zsh session."
    if command -v zsh &>/dev/null; then
        "log $INFO ""Zsh is available. Switching to zsh."
        # Change the default shell to Zsh
        sudo chsh -s $(command -v zsh) $(whoami)
        export SHELL=$(command -v zsh)
        exec zsh
    elif command -v bash &>/dev/null; then
        "log $INFO ""Bash is available. Switching to bash."
        # Change the default shell to Bash
        sudo chsh -s $(command -v bash) $(whoami)
        export SHELL=$(command -v bash)
        exec bash
    else
        "log $ERROR ""Neither Zsh nor Bash is installed. Please install one of them first."
    fi
fi
