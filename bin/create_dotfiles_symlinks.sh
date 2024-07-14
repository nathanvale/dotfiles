#!/bin/bash

# Inline symlink configuration
declare -A symlinks
symlinks["${HOME}/.config"]="${HOME}/code/dotfiles/config"
symlinks["${HOME}/Scripts"]="${HOME}/code/dotfiles/Scripts"
symlinks["${HOME}/.bin"]="${HOME}/code/dotfiles/bin"

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

# Iterate over the symlinks and create/update them
for link_name in "${!symlinks[@]}"; do
	target="${symlinks[$link_name]}"
	create_symlink "$target" "$link_name"
done

echo "Symlink creation process completed."
