#!/bin/bash

set -e

# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

log $INFO "Attempting Homebrew installation..."

# Function to handle errors and interruptions
handle_cleanup() {
  log $ERROR "$1"
  log $INFO "Running the official Homebrew uninstall script..."
  trap 'handle_cleanup "Homebrew uninstallation interrupted."' HUP INT QUIT TERM
  if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"; then
    handle_cleanup "Homebrew uninstallation script failed."
  else
    log $INFO "Homebrew uninstallation complete."
    exit 1
  fi
}

trap 'handle_cleanup "Homebrew installation interrupted."' HUP INT QUIT TERM

# Check if Homebrew is already installed by looking for /opt/homebrew/bin/brew
if [ -f /opt/homebrew/bin/brew ]; then
  log $INFO "Homebrew is already installed."
  exit 0
fi

if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
  handle_cleanup "Failed to run the official Homebrew install script."
fi

log $INFO "Homebrew installation complete."
