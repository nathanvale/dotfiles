#!/bin/bash

echo "Starting Homebrew uninstallation..."

# Run the official Homebrew uninstall script
echo "Running the official Homebrew uninstall script..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

echo "Homebrew uninstallation complete."
