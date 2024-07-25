#!/bin/bash

set -e

echo "Starting Homebrew bundle..."

# Temporarily add Homebrew to PATH
BREW_PATH="/opt/homebrew/bin"
export PATH="$BREW_PATH:$PATH"

# Define the URL of the Brewfile
BREWFILE_URL="https://raw.githubusercontent.com/nathanvale/dotfiles/master/config/brew/Brewfile"

# Define a temporary file to store the downloaded Brewfile
TEMP_BREWFILE=$(mktemp)

# Define the cleanup function
cleanup() {
  rm -f "$TEMP_BREWFILE"
  brew cleanup
}

ignore_sigint() {
  echo "Ignoring SIGINT..."
  exit 0
}

trap ignore_sigint SIGINT

if [ -n "$GITHUB_TOKEN" ]; then
  auth_header="Authorization: token $GITHUB_TOKEN"
else
  auth_header=""
fi

# Download the Brewfile using curl with authorization if available
echo "Downloading Brewfile from $BREWFILE_URL..."
if [ -n "$auth_header" ]; then
  status_code=$(curl -w "%{http_code}" -H "$auth_header" -L -s -o "$TEMP_BREWFILE" "$BREWFILE_URL")
else
  status_code=$(curl -w "%{http_code}" -L -s -o "$TEMP_BREWFILE" "$BREWFILE_URL")
fi

# Check if the download was successful
if [ "$status_code" -ne 200 ]; then
  echo "Failed to download $BREWFILE_URL (status code: $status_code)"
  # Check if the GITHUB_TOKEN environment variable is not set
  if [ -z "$auth_header" ]; then
    echo "Make sure to set the GITHUB_TOKEN environment variable if $BREWFILE_URL exists in a private repo."
    echo "For public repos, you can ignore this message."
    echo "export GITHUB_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  fi
  cleanup
  exit 1
fi

# Run brew bundle with the downloaded Brewfile
echo "Running brew bundle..."

if ! brew bundle --file=$TEMP_BREWFILE; then
  echo "Failed to run brew bundle."
  # Ask to contnue with installation anyway
  read -p "Do you want to continue with the installation anyway? (y/n) " -n 1 -r

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    cleanup
    exit 1
  fi
fi

cleanup

echo "Homebrew bundle complete."
