#!/bin/bash

# Check if the script is being run in zsh or bash
if [[ "$SHELL" == */bash ]] || [[ "$SHELL" == */zsh ]] || [[ "$(basename $0)" == "zsh" ]] || [[ "$(basename $0)" == "bash" ]]; then
    echo "Script is being run in bash or zsh."
else
    echo "Error: This script must be run in bash or zsh."
    exit 1
fi

# Your script's main functionality goes here
echo "Your script is now running..."
