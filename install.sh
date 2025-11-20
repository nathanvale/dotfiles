#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Navigate to the directory containing this script
cd "$(dirname "$0")"

echo "Installing nathanvale/dotfiles..."
echo "Running individual installation scripts in order..."

# Execute individual installation scripts
# Scripts should be run in dependency order (to be defined)
# For now, run scripts from bin/dotfiles/, bin/system/, etc. as needed

echo "Installation completed successfully."
