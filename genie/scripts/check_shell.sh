#!/bin/bash

# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

if [ "$SHELL" == "/bin/bash" ]; then
    log $INFO "Script is being run in bash."
elif [ "$SHELL" == "/bin/zsh" ]; then
    log $INFO "Script is being run in zsh."
else
    log $ERROR "This script must be run from a bash or zsh session."
    exit 1
fi
