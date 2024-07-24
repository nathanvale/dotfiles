#!/bin/bash

FISH_PATH="/opt/homebrew/bin/fish"

# Exit immediately if a command exits with a non-zero status
set -e

# Check if Fish is already in the list of allowed shells
if ! grep -q "$FISH_PATH" /etc/shells; then
    echo $FISH_PATH | sudo tee -a /etc/shells
    echo "Fish shell added to the list of allowed shells."
else
    echo "Fish shell already in the list of allowed shells."
fi

# Change the default shell to Fish
sudo chsh -s $FISH_PATH $(whoami)

# Print confirmation message
echo "Fish shell is now installed and set as the default shell."

# Optionally start Fish shell immediately
exec $FISH_PATH
