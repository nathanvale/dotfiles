#!/bin/bash

echo "Starting Homebrew installation..."

# Check if Homebrew is already installed
if command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew is already installed."
  exit 1
fi

# Run the official Homebrew install script
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "Homebrew installation complete."
