#!/bin/bash

# Resolve the absolute path of the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the colour_log.sh script
source "$SCRIPT_DIR/colour_log.sh"

set -e

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

# Check if Homebrew is already installed by looking for /opt/homebrew/bin/fish
if [ -f /opt/homebrew/bin/fish ]; then
  log $INFO "Homebrew is already installed."
  exit 0
fi

if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
  handle_cleanup "Failed to run the official Homebrew install script."
fi

log $INFO "Homebrew installation complete."
