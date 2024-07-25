#!/bin/bash

if [ "$SHELL" == "/bin/bash" ]; then
    echo "Script is being run in bash."
elif [ "$SHELL" == "/bin/zsh" ]; then
    echo "Script is being run in zsh."
else
    echo "Error: This script must be run from a bash or zsh session."
    exit 1
fi
