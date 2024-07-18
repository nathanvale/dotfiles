#!/bin/bash

echo "Starting Homebrew installation..."

# Run the official Homebrew install script
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to your PATH
echo "Adding Homebrew to your PATH..."

# Determine which shell configuration file to use
if [ -f "$HOME/.zshrc" ]; then
  CONFIG_FILE="$HOME/.zshrc"
elif [ -f "$HOME/.bash_profile" ]; then
  CONFIG_FILE="$HOME/.bash_profile"
elif [ -f "$HOME/.bashrc" ]; then
  CONFIG_FILE="$HOME/.bashrc"
else
  # Default to .bash_profile if none of the above exists
  CONFIG_FILE="$HOME/.bash_profile"
fi

# Add the following lines to the shell configuration file
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $CONFIG_FILE
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "Homebrew installation complete. Please restart your terminal or run 'source $CONFIG_FILE' to start using Homebrew."
