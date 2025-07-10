#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Navigate to the directory containing this script
cd "$(dirname "$0")"

echo "Installing nathanvale/dotfiles..."
echo "Running installation script..."

# Execute the installation script
./bin/install-dotfiles.sh

echo "Installation completed successfully."
