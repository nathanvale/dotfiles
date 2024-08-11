#!/bin/bash

set -e

# Variables
KEY_NAME="id_rsa_github"
KEY_PATH="$HOME/.ssh/$KEY_NAME"

SSH_CONFIG_FILE="$HOME/.ssh/config"
GITHUB_HOSTNAME="github.com"
CLONE_DIR="$HOME/code/dotfiles"
#.config folder
CONFIG_DIR="$HOME/.config"
# Resolve the absolute path of the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/colour_log.sh"
source "$SCRIPT_DIR/ssh_config_remove.sh"

cleanup() {
    log $INFO "Cleaning up generated SSH key..."
    rm -f "$KEY_PATH" "$KEY_PATH.pub"
    rm -rf "$CLONE_DIR"
    rm -rf "$CONFIG_DIR"
    ssh_config_remove "$GITHUB_HOSTNAME" "$SSH_CONFIG_FILE"
    # Check if the SSH config file exists and is empty, then delete it
    if [ -e "$SSH_CONFIG_FILE" ] && [ ! -s "$SSH_CONFIG_FILE" ]; then
        log $INFO "Deleting empty SSH config file..."
        rm "$SSH_CONFIG_FILE"
    fi
}

log $INFO "Attempting to uninstall $GITHUB_HOSTNAME/$REPO_URL from this computer..."

cleanup

log $INFO "Dotfiles uninstalled successfully."
