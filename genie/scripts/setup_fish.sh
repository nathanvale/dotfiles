#!/bin/bash

# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

FISH_PATH="/opt/homebrew/bin/fish"

# Exit immediately if a command exits with a non-zero status
set -e

# Check if Fish is already in the list of allowed shells
if ! grep -q "$FISH_PATH" /etc/shells; then
    echo $FISH_PATH | sudo tee -a /etc/shells
    log $INFO "Fish shell added to the list of allowed shells."
else
    log $INFO "Fish shell already in the list of allowed shells."
fi

# Change the default shell to Fish
sudo chsh -s $FISH_PATH $(whoami)
export SHELL=$FISH_PATH

# Print confirmation message
log $INFO "Fish shell is now installed and set as the default shell."
