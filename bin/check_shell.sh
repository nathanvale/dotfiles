#!/bin/bash

# Get the parent shell name
parent_shell=$(ps -o comm= -p $(ps -o ppid= -p $$))

echo "Parent shell: $parent_shell"

# Check if the parent shell is bash or zsh
if [[ "$parent_shell" == "bash" ]] || [[ "$parent_shell" == "zsh" ]]; then
    echo "Script is being run in bash or zsh."
else
    echo "Error: This script must be run from a bash or zsh session."
    exit 1
fi

# Your script's main functionality goes here
echo "Your script is now running..."
