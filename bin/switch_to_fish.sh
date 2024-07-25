#!/bin/bash

if command -v fish >/dev/null 2>&1; then
    sudo chsh -s $(which fish) $(whoami)
    export SHELL=$(which fish)
    exec fish
else
    echo "Fish shell is not installed. Please install fish first."
fi
