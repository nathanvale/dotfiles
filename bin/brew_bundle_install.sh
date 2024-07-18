#!/bin/bash

# Define the URL of the Brewfile
BREWFILE_URL="https://raw.githubusercontent.com/nathanvale/dotfiles/master/config/brew/Brewfile"

# Define a temporary file to store the downloaded Brewfile
TEMP_BREWFILE=$(mktemp)

# Download the Brewfile using curl
echo "Downloading Brewfile from $BREWFILE_URL..."
curl -L $BREWFILE_URL -o $TEMP_BREWFILE

# Check if the file was downloaded successfully
if [ $? -ne 0 ]; then
  echo "Failed to download the Brewfile."
  exit 1
fi

# Run brew bundle with the downloaded Brewfile
echo "Running brew bundle..."
/opt/homebrew/bin/brew bundle --file=$TEMP_BREWFILE

# Check if brew bundle ran successfully
if [ $? -ne 0 ]; then
  echo "Failed to run brew bundle."
  exit 1
fi

# Cleanup: Remove the temporary Brewfile
rm $TEMP_BREWFILE

echo "Brew bundle completed successfully."
