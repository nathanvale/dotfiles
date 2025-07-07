#!/bin/bash

set -e

# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

symlinks=(
	"${HOME}/.config|${HOME}/code/dotfiles/config"
	"${HOME}/Scripts|${HOME}/code/dotfiles/Scripts"
	"${HOME}/bin|${HOME}/code/dotfiles/bin"
	"${HOME}/.zprofile|${HOME}/code/dotfiles/.zprofile"
	"${HOME}/.zshrc|${HOME}/code/dotfiles/.zshrc"
	"${HOME}/.gitconfig|${HOME}/code/dotfiles/.gitconfig"
	"${HOME}/.gitignore_global|${HOME}/code/dotfiles/.gitignore_global"
)

# Function to display usage
usage() {
	echo "Usage: $0 [-l | --link] [-u | --unlink] [-h | --help]"
	echo "  -l, --link    Create symlinks"
	echo "  -u, --unlink  Remove symlinks"
	echo "  -h, --help    Display this help message"
	exit 1
}

# Function to create symlink if it doesn't already exist or is incorrect
create_symlink() {
	local target=$1
	local link_name=$2

	if [ -L "$link_name" ]; then
		if [ "$(readlink "$link_name")" == "$target" ]; then
			log $INFO "Symlink $link_name already exists and points to the correct target."
		else
			log $WARNING "Symlink $link_name exists but points to the wrong target. Updating..."
			ln -sf "$target" "$link_name"
			log $INFO "Symlink updated: $link_name -> $target"
		fi
	elif [ -e "$link_name" ]; then
		log $WARNING "File or directory $link_name already exists and is not a symlink."
		read -p "Would you like to remove it? [y/N] " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			rm -rf "$link_name"
			log $INFO "Removing $link_name..."
			ln -s "$target" "$link_name"
			log $INFO "Symlink created: $link_name -> $target"
		else
			log $INFO "Skipping $link_name"
		fi
	else
		ln -s "$target" "$link_name"
		log $INFO "Symlink created: $link_name -> $target"
	fi
}

# Function to remove symlink if it exists
remove_symlink() {
	local link_name=$1
	if [ -L "$link_name" ]; then
		rm "$link_name"
		log $INFO "Symlink removed: $link_name"
	elif [ -e "$link_name" ]; then
		log $INFO "File or directory $link_name exists and is not a symlink."
	else
		log $INFO "Symlink $link_name does not exist."
	fi
}

# Function to run the script
run_symlink_creation() {
	for entry in "${symlinks[@]}"; do
		link_name="${entry%%|*}"
		target="${entry##*|}"
		create_symlink "$target" "$link_name"
	done
	log $INFO "Symlink creation process completed."
}

# Function to run the script
run_symlink_removal() {
	for entry in "${symlinks[@]}"; do
		link_name="${entry%%|*}"
		remove_symlink "$link_name"
	done
	log $INFO "Symlink removal process completed."
}

# Main execution
if [ $# -eq 0 ]; then
	usage
fi

while [[ $# -gt 0 ]]; do
	case "$1" in
	-l | --link)
		run_symlink_creation
		shift
		;;
	-u | --unlink)
		run_symlink_removal
		shift
		;;
	-h | --help)
		usage
		;;
	*)
		usage
		;;
	esac
done
