#!/bin/bash

# Source the color_log.sh script
source ./colour_log.sh

if [ "$SHELL" == "/bin/bash" ]; then
    log $INFO "Script is being run in bash."
elif [ "$SHELL" == "/bin/zsh" ]; then
    log $INFO "Script is being run in zsh."
else
    log $ERROR "Error: This script must be run from a bash or zsh session."
    exit 1
fi
