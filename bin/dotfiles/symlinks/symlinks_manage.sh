#!/bin/bash
# symlinks_manage.sh - Create and manage dotfiles symlinks
#
# Usage:
#   symlinks_manage.sh --link      Create all symlinks
#   symlinks_manage.sh --unlink    Remove all symlinks
#   symlinks_manage.sh --status    Show current symlink status
#   symlinks_manage.sh --dry-run   Preview what would be done (with --link or --unlink)
#   symlinks_manage.sh --force     Replace existing files/dirs without prompting
#
# This script is portable - it auto-detects the dotfiles location.

set -e

# Auto-detect dotfiles directory (3 levels up from this script)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# VS Code user directory (macOS)
VSCODE_USER="${HOME}/Library/Application Support/Code/User"

# Source logging utilities
source "$DOTFILES/bin/colour_log.sh"

# Symlinks configuration: "link_path|target_path"
# The link_path is where the symlink will be created
# The target_path is what it points to (in the dotfiles repo)
symlinks=(
	# Shell configuration
	"${HOME}/.zshrc|${DOTFILES}/.zshrc"
	"${HOME}/.zprofile|${DOTFILES}/.zprofile"

	# Git configuration
	"${HOME}/.gitconfig|${DOTFILES}/.gitconfig"
	"${HOME}/.gitignore_global|${DOTFILES}/.gitignore_global"
	"${HOME}/.gitmessage|${DOTFILES}/.gitmessage"

	# XDG config directory (symlinks entire .config)
	"${HOME}/.config|${DOTFILES}/config"

	# Bin directories
	"${HOME}/bin|${DOTFILES}/bin"
	"${HOME}/Scripts|${DOTFILES}/Scripts"

	# Tmux (doesn't follow XDG, needs explicit symlink)
	"${HOME}/.tmux.conf|${DOTFILES}/config/tmux/tmux.conf"

	# VS Code
	"${VSCODE_USER}/settings.json|${DOTFILES}/config/vscode/settings.json"
	"${VSCODE_USER}/tasks.json|${DOTFILES}/config/vscode/tasks.json"
	"${VSCODE_USER}/keybindings.json|${DOTFILES}/config/vscode/keybindings.json"
	"${VSCODE_USER}/prompts|${DOTFILES}/config/vscode/prompts"
	"${VSCODE_USER}/mcp.json|${DOTFILES}/config/vscode/mcp.json"

	# SuperWhisper (app stores recordings/modes here)
	"${HOME}/Documents/superwhisper|${DOTFILES}/config/superwhisper"
)

# Flags
DRY_RUN=false
FORCE=false

usage() {
	echo "Usage: $0 [OPTIONS] COMMAND"
	echo ""
	echo "Commands:"
	echo "  -l, --link      Create symlinks"
	echo "  -u, --unlink    Remove symlinks"
	echo "  -s, --status    Show current symlink status"
	echo ""
	echo "Options:"
	echo "  -f, --force     Replace existing files/dirs without prompting"
	echo "  -n, --dry-run   Preview changes without making them"
	echo "  -h, --help      Show this help message"
	echo ""
	echo "Dotfiles location: $DOTFILES"
	exit 1
}

# Create parent directory if it doesn't exist
ensure_parent_dir() {
	local path="$1"
	local parent_dir
	parent_dir="$(dirname "$path")"

	if [[ ! -d "$parent_dir" ]]; then
		if $DRY_RUN; then
			log "$INFO" "[DRY-RUN] Would create directory: $parent_dir"
		else
			mkdir -p "$parent_dir"
			log "$INFO" "Created directory: $parent_dir"
		fi
	fi
}

# Create symlink if it doesn't already exist or is incorrect
create_symlink() {
	local target=$1
	local link_name=$2

	# Check if target exists in dotfiles
	if [[ ! -e "$target" ]]; then
		log "$WARNING" "Target does not exist: $target (skipping)"
		return
	fi

	# Ensure parent directory exists
	ensure_parent_dir "$link_name"

	if [[ -L "$link_name" ]]; then
		if [[ "$(readlink "$link_name")" == "$target" ]]; then
			log "$INFO" "Already correct: $link_name"
		else
			if $DRY_RUN; then
				log "$WARNING" "[DRY-RUN] Would update: $link_name -> $target"
			else
				ln -sf "$target" "$link_name"
				log "$INFO" "Updated: $link_name -> $target"
			fi
		fi
	elif [[ -e "$link_name" ]]; then
		log "$WARNING" "Exists but not a symlink: $link_name"
		if $DRY_RUN; then
			log "$WARNING" "[DRY-RUN] Would prompt to replace: $link_name"
		elif $FORCE; then
			# Force mode: backup and replace without prompting
			local backup="${link_name}.backup.$(date +%Y%m%d%H%M%S)"
			mv "$link_name" "$backup"
			ln -s "$target" "$link_name"
			log "$INFO" "Backed up to: $backup"
			log "$INFO" "Replaced: $link_name -> $target"
		elif [[ -t 0 ]]; then
			# Interactive mode: prompt user
			read -p "Remove and replace with symlink? [y/N] " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				rm -rf "$link_name"
				ln -s "$target" "$link_name"
				log "$INFO" "Replaced: $link_name -> $target"
			else
				log "$INFO" "Skipped: $link_name"
			fi
		else
			# Non-interactive mode without --force: skip
			log "$WARNING" "Skipped (non-interactive, use --force to replace): $link_name"
		fi
	else
		if $DRY_RUN; then
			log "$INFO" "[DRY-RUN] Would create: $link_name -> $target"
		else
			ln -s "$target" "$link_name"
			log "$INFO" "Created: $link_name -> $target"
		fi
	fi
}

# Remove symlink if it exists
remove_symlink() {
	local link_name=$1

	if [[ -L "$link_name" ]]; then
		if $DRY_RUN; then
			log "$INFO" "[DRY-RUN] Would remove: $link_name"
		else
			rm "$link_name"
			log "$INFO" "Removed: $link_name"
		fi
	elif [[ -e "$link_name" ]]; then
		log "$WARNING" "Not a symlink (skipping): $link_name"
	else
		log "$INFO" "Does not exist: $link_name"
	fi
}

# Show status of all symlinks
show_status() {
	echo ""
	echo "Dotfiles: $DOTFILES"
	echo ""
	printf "%-50s %-10s %s\n" "LINK" "STATUS" "TARGET"
	printf "%-50s %-10s %s\n" "----" "------" "------"

	for entry in "${symlinks[@]}"; do
		local link_name="${entry%%|*}"
		local target="${entry##*|}"
		local status
		local actual_target=""

		# Shorten paths for display
		local display_link="${link_name/#$HOME/~}"

		if [[ -L "$link_name" ]]; then
			actual_target="$(readlink "$link_name")"
			if [[ "$actual_target" == "$target" ]]; then
				status="OK"
			else
				status="WRONG"
			fi
		elif [[ -e "$link_name" ]]; then
			status="EXISTS"
			actual_target="(not a symlink)"
		else
			status="MISSING"
			actual_target="-"
		fi

		# Color the status
		case $status in
		OK) printf "%-50s \033[0;32m%-10s\033[0m %s\n" "$display_link" "$status" "${actual_target/#$DOTFILES/\$DOTFILES}" ;;
		WRONG) printf "%-50s \033[0;33m%-10s\033[0m %s\n" "$display_link" "$status" "${actual_target/#$HOME/~}" ;;
		EXISTS) printf "%-50s \033[0;33m%-10s\033[0m %s\n" "$display_link" "$status" "$actual_target" ;;
		MISSING) printf "%-50s \033[0;31m%-10s\033[0m %s\n" "$display_link" "$status" "$actual_target" ;;
		esac
	done
	echo ""
}

# Run symlink creation
run_symlink_creation() {
	log "$INFO" "Creating symlinks..."
	if $DRY_RUN; then
		log "$WARNING" "DRY-RUN mode - no changes will be made"
	fi
	echo ""

	for entry in "${symlinks[@]}"; do
		local link_name="${entry%%|*}"
		local target="${entry##*|}"
		create_symlink "$target" "$link_name"
	done

	echo ""
	if $DRY_RUN; then
		log "$INFO" "Dry run complete. Run without --dry-run to apply changes."
	else
		log "$INFO" "Symlink creation complete."
	fi
}

# Run symlink removal
run_symlink_removal() {
	log "$INFO" "Removing symlinks..."
	if $DRY_RUN; then
		log "$WARNING" "DRY-RUN mode - no changes will be made"
	fi
	echo ""

	for entry in "${symlinks[@]}"; do
		local link_name="${entry%%|*}"
		remove_symlink "$link_name"
	done

	echo ""
	if $DRY_RUN; then
		log "$INFO" "Dry run complete. Run without --dry-run to apply changes."
	else
		log "$INFO" "Symlink removal complete."
	fi
}

# Parse arguments
if [[ $# -eq 0 ]]; then
	usage
fi

COMMAND=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	-l | --link)
		COMMAND="link"
		shift
		;;
	-u | --unlink)
		COMMAND="unlink"
		shift
		;;
	-s | --status)
		COMMAND="status"
		shift
		;;
	-n | --dry-run)
		DRY_RUN=true
		shift
		;;
	-f | --force)
		FORCE=true
		shift
		;;
	-h | --help)
		usage
		;;
	*)
		log "$ERROR" "Unknown option: $1"
		usage
		;;
	esac
done

# Execute command
case "$COMMAND" in
link)
	run_symlink_creation
	;;
unlink)
	run_symlink_removal
	;;
status)
	show_status
	;;
"")
	log "$ERROR" "No command specified"
	usage
	;;
esac
