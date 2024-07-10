#!/bin/bash

# Function to create symlink if it doesn't already exist or is incorrect
create_symlink() {
  local target=$1
  local link_name=$2

  if [ -L "$link_name" ]; then
    if [ "$(readlink "$link_name")" == "$target" ]; then
      echo "Symlink $link_name already exists and points to the correct target."
    else
      echo "Symlink $link_name exists but points to the wrong target. Updating..."
      ln -sf "$target" "$link_name"
      echo "Symlink updated: $link_name -> $target"
    fi
  elif [ -e "$link_name" ]; then
    echo "File or directory $link_name already exists and is not a symlink."
  else
    ln -s "$target" "$link_name"
    echo "Symlink created: $link_name -> $target"
  fi
}

# Path to the JSON configuration file
CONFIG_FILE="${HOME}/code/dotfiles/config/symlinks/symlinks.json"

# Read JSON file and iterate over the symlinks
symlinks=$(jq -r '.symlinks[] | "\(.target) \(.link_name)"' "$CONFIG_FILE")

# Replace ${HOME} with the actual home directory path
symlinks=$(echo "$symlinks" | sed "s|\${HOME}|$HOME|g")

# Iterate over the symlinks
while IFS= read -r line; do
  target=$(echo "$line" | awk '{print $1}')
  link_name=$(echo "$line" | awk '{print $2}')
  create_symlink "$target" "$link_name"
done <<< "$symlinks"

echo "Symlink creation process completed."
