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
		read -p "Would you like to remove it? (y/n): " response
		if [[ "$response" == "y" ]]; then
			rm -rf "$link_name"
			echo "Removed $link_name"
			ln -s "$target" "$link_name"
			echo "Symlink created: $link_name -> $target"
		else
			echo "Skipping $link_name"
		fi
	else
		ln -s "$target" "$link_name"
		echo "Symlink created: $link_name -> $target"
	fi
}

# Function to remove symlink if it exists
remove_symlink() {
	local link_name=$1

	if [ -L "$link_name" ]; then
		rm "$link_name"
		echo "Symlink removed: $link_name"
	elif [ -e "$link_name" ]; then
		echo "File or directory $link_name exists and is not a symlink. Skipping..."
	else
		echo "Symlink $link_name does not exist."
	fi
}

# Function to run the script
run_symlink_creation() {
	for entry in "${symlinks[@]}"; do
		link_name="${entry%%|*}"
		target="${entry##*|}"
		create_symlink "$target" "$link_name"
	done
	echo "Symlink creation process completed."
}

# Function to run the script
run_symlink_removal() {
	for entry in "${symlinks[@]}"; do
		link_name="${entry%%|*}"
		remove_symlink "$link_name"
	done
	echo "Symlink removal process completed."
}

# Check if script is running in a pipeline
is_pipelined() {
	[ ! -t 0 ]
}

# Main execution
if is_pipelined; then
	if [ "$1" == "--unlink" ]; then
		echo "Running remotely via pipeline to remove symlinks."
		run_symlink_removal
	else
		echo "Running remotely via pipeline to create symlinks."
		run_symlink_creation
	fi
elif [ -z "$SSH_TTY" ]; then
	if [ "$1" == "--unlink" ]; then
		echo "Running locally to remove symlinks."
		run_symlink_removal
	else
		echo "Running locally to create symlinks."
		run_symlink_creation
	fi
else
	echo "Unknown execution context."
	exit 1
fi
