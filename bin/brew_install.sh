#!/bin/bash

echo "Starting Homebrew installation..."

# Function to handle errors and interruptions
handle_cleanup() {
  echo "Error: $1"
  echo "Cleaning up..."
  echo "Running the official Homebrew uninstall script..."
  trap 'handle_cleanup "Homebrew uninstallation interrupted."' SIGINT
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
  if [ $? -ne 0 ]; then
    handle_cleanup "Homebrew uninstallation script failed."
  fi
  exit 1
}

# Trap SIGINT (Control-C)
trap 'handle_cleanup "Homebrew installation interrupted."' SIGINT

# Check if Homebrew is already installed by looking for /opt/homebrew/bin/fish
if [ -f /opt/homebrew/bin/fish ]; then
  echo "Homebrew is already installed."
  exit 0
fi


# Run the official Homebrew install script
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
if [ $? -ne 0 ]; then
  handle_cleanup "Homebrew installation script failed."
fi

echo "Homebrew installation complete."
