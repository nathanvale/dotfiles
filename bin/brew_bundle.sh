#!/bin/bash

# Define the URL of the Brewfile
BREWFILE_URL="https://raw.githubusercontent.com/nathanvale/dotfiles/master/config/brew/Brewfile"

# Define a temporary file to store the downloaded Brewfile
TEMP_BREWFILE=$(mktemp)

if [ -n "$GITHUB_TOKEN" ]; then
  auth_header="Authorization: token $GITHUB_TOKEN"
else
  auth_header=""
fi

# Download the Brewfile using curl
echo "Downloading Brewfile from $BREWFILE_URL..."
curl -L $BREWFILE_URL -o $TEMP_BREWFILE

# Download the script
echo "Downloading $url..."
if [ -n "$auth_header" ]; then
  status_code=$(curl -w "%{http_code}" -H "$auth_header" -s -o "$TEMP_BREWFILE" "$BREWFILE_URL")
else
  status_code=$(curl -w "%{http_code}" -s -o "$TEMP_BREWFILE" "$BREWFILE_URL")
fi

# Check if the download was successful
if [ "$status_code" -ne 200 ]; then
  echo "Failed to download $BREWFILE_URL (status code: $status_code)"
  return 1
fi

# Run brew bundle with the downloaded Brewfile
echo "Running brew bundle..."
/opt/homebrew/bin/brew bundle --file=$TEMP_BREWFILE

# Cleanup: Remove the temporary Brewfile
rm $TEMP_BREWFILE
