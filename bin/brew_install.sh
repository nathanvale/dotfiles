#!/bin/bash

set -e

echo "Starting Homebrew installation..."

# Function to handle errors and interruptions
handle_cleanup() {
  echo "Error: $1"
  echo "Running the official Homebrew uninstall script..."
  trap 'handle_cleanup "Homebrew uninstallation interrupted."' INT QUIT TERM
  if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"; then
    handle_cleanup "Homebrew uninstallation script failed."
  else
    echo "Homebrew uninstallation complete."
    exit 1
  fi
}

# Trap INT (Control-C)
trap 'handle_cleanup "Homebrew installation interrupted."' INT QUIT TERM

# Check if Homebrew is already installed by looking for /opt/homebrew/bin/fish
if [ -f /opt/homebrew/bin/fish ]; then
  echo "Homebrew is already installed."
  exit 0
fi

if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
  handle_cleanup "Failed to run the official Homebrew install script."
fi

echo "Homebrew installation complete."
