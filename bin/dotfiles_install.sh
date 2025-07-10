#!/bin/bash

set -e

# Variables
KEY_NAME="id_rsa_github"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
KEY_COMMENT="hi@nathanvale.com"
SSH_CONFIG_FILE="$HOME/.ssh/config"
GITHUB_HOSTNAME="github.com"
GITHUB_SCOPES="admin:public_key,admin:ssh_signing_key"
REPO_URL="nathanvale/dotfiles"
CLONE_DIR="$HOME/code/dotfiles"
SSH_CONFIG_CLEANUP_REQUIRED=false
# Resolve the absolute path of the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/colour_log.sh"
source "$SCRIPT_DIR/ssh_config_remove.sh"

# GH wont login if this key exists
unset GITHUB_TOKEN

# Temporarily add GitHub CLI to PATH
GH_CLI_PATH="/opt/homebrew/bin"
export PATH="$GH_CLI_PATH:$PATH"

cleanup() {
    if [ "$SSH_CONFIG_CLEANUP_REQUIRED" = true ]; then
        log $INFO "Cleaning up generated SSH key..."
        rm -f "$KEY_PATH" "$KEY_PATH.pub"
        ssh_config_remove "$GITHUB_HOSTNAME" "$SSH_CONFIG_FILE"
        # Check if the SSH config file exists and is empty, then delete it
        if [ -e "$SSH_CONFIG_FILE" ] && [ ! -s "$SSH_CONFIG_FILE" ]; then
            log $INFO "Deleting empty SSH config file..."
            rm "$SSH_CONFIG_FILE"
        fi
    fi
    SSH_CONFIG_CLEANUP_REQUIRED=false
}

trap cleanup EXIT

log $INFO "Attempting to install $GITHUB_HOSTNAME/$REPO_URL on this computer..."

# Check if the clone directory exists and is a Git repository
if [ -d "$CLONE_DIR" ] && [ -d "$CLONE_DIR/.git" ]; then
    log $ERROR "Directory $CLONE_DIR already exists and is a Git repository."
    exit 1
fi

# Check if the GitHub CLI is installed
if ! command -v gh &>/dev/null; then
    log $ERROR "GitHub CLI (gh) could not be found. Please install it and try again."
    exit 1
fi

# Check if SSH configuration already exists for the exact key name
if [ -f "$KEY_PATH" ] && [ -f "$KEY_PATH.pub" ]; then
    log $INFO "Using the github.com SSH key that already exists."
else
    SSH_CONFIG_CLEANUP_REQUIRED=true
    cleanup
    # Generate SSH key
    ssh-keygen -t rsa -b 4096 -C "$KEY_COMMENT" -f "$KEY_PATH" -q -N ""
    # Create SSH config file if it doesn't exist
    if [ ! -f "$SSH_CONFIG_FILE" ]; then
        touch "$SSH_CONFIG_FILE"
    fi

    cat <<EOL >>"$SSH_CONFIG_FILE"

Host $GITHUB_HOSTNAME
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/$KEY_NAME
EOL
    # Trim leading blank lines from the SSH config file
    sed -i '' '/./,$!d' "$SSH_CONFIG_FILE"
    # Add the new SSH key to the SSH agent
    ssh-add "$KEY_PATH"
    SSH_CONFIG_CLEANUP_REQUIRED=true
fi

# Determine whether to use login or refresh
if gh auth status &>/dev/null; then
    gh auth refresh --hostname "$GITHUB_HOSTNAME" --scopes "$GITHUB_SCOPES"
else
    gh auth login --hostname "$GITHUB_HOSTNAME" --web --git-protocol ssh --skip-ssh-key --scopes "$GITHUB_SCOPES"
fi
log $INFO "Enter a title for your SSH key (e.g. 'Work Laptop' or 'Personal Laptop'):"
read -r TITLE

# Add SSH key to GitHub
if ! gh ssh-key add "$KEY_PATH.pub" -t "$TITLE"; then
    log $ERROR "Failed to add SSH key to GitHub. Please check the above error message and try again."
    exit 1
fi

SSH_CONFIG_CLEANUP_REQUIRED=false
log $INFO "SSH key successfully added to GitHub."

# Create the directory for cloning if it doesn't exist
mkdir -p "$CLONE_DIR"

# Clone the repository using gh
log $INFO "Cloning repository $REPO_URL into $CLONE_DIR..."

if ! gh repo clone "$REPO_URL" "$CLONE_DIR"; then
    log $ERROR "Failed to clone $REPO_URL. Please check the above error message and try again."
    exit 1
fi

gh auth logout

log $INFO "Repository successfully cloned."
