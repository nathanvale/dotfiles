#!/bin/bash

# Resolve the absolute path of the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the colour_log.sh script
source "$SCRIPT_DIR/colour_log.sh"

if [ "$SHELL" == "/bin/bash" ]; then
    log $INFO "Script is being run in bash."
elif [ "$SHELL" == "/bin/zsh" ]; then
    log $INFO "Script is being run in zsh."
else
    log $ERROR "Error: This script must be run from a bash or zsh session."
    exit 1
fi
