#!/bin/bash

# This script is used to remotely install Homebrew packages from a Brewfile.
# It downloads the Brewfile from a specified URL and installs the packages using Homebrew.
# If Homebrew is not installed, it prompts the user to install it.
# The script also handles interruptions and cleanup.

set -e

# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

INSTALLING_BREW_PACKAGES=false
# Temporarily add Homebrew to PATH
BREW_PATH="/opt/homebrew/bin"
# Define the URL of the Brewfile
BREWFILE_URL="https://raw.githubusercontent.com/nathanvale/dotfiles/main/config/brew/Brewfile"
# Define a temporary file to store the downloaded Brewfile
TEMP_BREWFILE=$(mktemp)
export PATH="$BREW_PATH:$PATH"

# Define the cleanup function
cleanup() {
  "log $INFO ""Removing temporary Brewfile..."
  rm -f "$TEMP_BREWFILE"
  if command -v brew &>/dev/null; then
    brew cleanup
  fi
}

ignore_sigint() {
  # if installing brew packages prompt the user if the want to exit the script
  if [ "$INSTALLING_BREW_PACKAGES" = true ]; then
    "log $WARNING ""Installation of Homebrew bundle is in progress."
    read -p "Do you want to skip the installation? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      "log $INFO ""Installation of Homebrew packages skipped."
      cleanup
      exit 0
    fi
  fi
  "log $INFO ""Installation of Homebrew bundle stopped."
  cleanup
  exit 1
}

trap ignore_sigint SIGINT

"log $INFO ""Starting Homebrew bundle..."

# Check if brew command exists
if ! command -v brew &>/dev/null; then
  "log $ERROR ""Homebrew is not installed."
  "log $INFO ""Run the install script to install Homebrew."
  "log $INFO ""curl -fsSL https://raw.githubusercontent.com/nathanvale/dotfiles/main/setup.sh | /bin/bash"
  cleanup
  exit 1
fi

if [ -n "$GITHUB_TOKEN" ]; then
  auth_header="Authorization: token $GITHUB_TOKEN"
else
  auth_header=""
fi

# Download the Brewfile using curl with authorization if available
"log $INFO ""Downloading Brewfile from $BREWFILE_URL..."
if [ -n "$auth_header" ]; then
  status_code=$(curl -w "%{http_code}" -H "$auth_header" -L -s -o "$TEMP_BREWFILE" "$BREWFILE_URL")
else
  status_code=$(curl -w "%{http_code}" -L -s -o "$TEMP_BREWFILE" "$BREWFILE_URL")
fi

# Check if the download was successful
if [ "$status_code" -ne 200 ]; then
  "log $ERROR ""Failed to download $BREWFILE_URL (status code: $status_code)"
  # Check if the GITHUB_TOKEN environment variable is not set
  if [ -z "$auth_header" ]; then
    "log $ERROR ""Make sure to set the GITHUB_TOKEN environment variable if $BREWFILE_URL exists in a private repo."
    "log $INFO ""For public repos, you can ignore this message."
    "log $INFO ""export GITHUB_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  fi
  cleanup
  exit 1
fi

INSTALLING_BREW_PACKAGES=true
# Run brew bundle with the downloaded Brewfile
"log $INFO ""Installing Homebrew packages..."

if ! brew bundle --file="$TEMP_BREWFILE"; then
  "log $ERROR ""Failed to install Homebrew packages."
  ignore_sigint
fi

cleanup

"log $INFO ""Homebrew bundle complete."
