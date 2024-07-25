#!/bin/bash

if command -v fish >/dev/null 2>&1; then
    sudo chsh -s $(which fish) $(whoami)
    exec fish
else
    echo "Fish shell is not installed. Please install fish first."
fi
