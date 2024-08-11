#!/bin/bash

set -e

# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

log $INFO "Starting Homebrew uninstallation..."

# Run the official Homebrew uninstall script
log $INFO "Running the official Homebrew uninstall script..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

log $INFO "Homebrew uninstallation complete."
