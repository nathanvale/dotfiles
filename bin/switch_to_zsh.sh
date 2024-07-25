#!/bin/bash

if command -v zsh &>/dev/null; then
    # Change the default shell to Zsh
    sudo chsh -s $(command -v zsh) $(whoami)
    export SHELL=$(command -v zsh)
    exec zsh
else
    echo "Zsh shell is not installed. Please install Zsh first."
fi
