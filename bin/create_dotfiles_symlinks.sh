#!/bin/bash

# Define symlinks as an array of pairs
symlinks=(
	"${HOME}/.config|${HOME}/code/dotfiles/config"
	"${HOME}/Scripts|${HOME}/code/dotfiles/Scripts"
	"${HOME}/.bin|${HOME}/code/dotfiles/bin"
	"${HOME}/.zprofile|${HOME}/code/dotfiles/.zprofile"
	"${HOME}/.zshrc|${HOME}/code/dotfiles/.zshrc"
	"${HOME}/.gitconfig|${HOME}/code/dotfiles/.gitconfig"
	"${HOME}/.gitignore_global|${HOME}/code/dotfiles/.gitignore_global"
	"${HOME}/Library/LaunchAgents|${HOME}/code/dotfiles/LaunchAgents"
)

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
for entry in "${symlinks[@]}"; do
	link_name="${entry%%|*}"
	target="${entry##*|}"
	create_symlink "$target" "$link_name"
done

echo "Symlink creation process completed."
