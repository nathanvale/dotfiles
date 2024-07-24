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

# GH wont login if this key exists
unset GITHUB_TOKEN

# Temporarily add GitHub CLI to PATH
GH_CLI_PATH="/opt/homebrew/bin"
export PATH="$GH_CLI_PATH:$PATH"

cleanup() {
    if [ "$SSH_CONFIG_CLEANUP_REQUIRED" = true ]; then
        echo "Cleaning up generated SSH key..."
        rm -f "$KEY_PATH" "$KEY_PATH.pub"
        remove_git_sha_from_ssh_config

        # Check if the SSH config file exists and is empty, then delete it
        if [ -e "$SSH_CONFIG_FILE" ] && [ ! -s "$SSH_CONFIG_FILE" ]; then
            echo "Deleting empty SSH config file..."
            rm "$SSH_CONFIG_FILE"
        fi
    fi
    SSH_CONFIG_CLEANUP_REQUIRED=false
}

remove_git_sha_from_ssh_config() {
    # Check if SSH config file exists
    if [ -f "$SSH_CONFIG_FILE" ]; then
        # Normalize KEY_PATH to use ~ instead of the full home directory path
        KEY_PATH_NORMALISED="${KEY_PATH/#$HOME/~}"
        echo "Removing $KEY_PATH_NORMALISED from SSH config..."

        awk -v hostname="$GITHUB_HOSTNAME" -v keypath="$KEY_PATH_NORMALISED" '
        BEGIN {remove=0; first_host=1}
        {
            # Process each line
            if ($0 ~ "^[[:space:]]*Host[[:space:]]+" hostname "[[:space:]]*$") {
                remove=1
            }
            if (remove && $0 ~ "^[[:space:]]*IdentityFile[[:space:]]+" keypath "[[:space:]]*$") {
                remove=0
                next
            }
            if (!remove) {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "");  # Remove leading and trailing spaces
                if ($0 ~ "^Host[[:space:]]*") {
                    if (!first_host) {
                        print ""  # Print a blank line before each Host line
                    }
                    first_host=0
                    print $0
                } else if ($0 != "") {
                    print "\t" $0
                } else {
                    print $0
                }
            }
        }' "$SSH_CONFIG_FILE" >"$SSH_CONFIG_FILE.tmp"

        # Use sed to ensure exactly one blank line between Host blocks
        sed -i.bak -e '/^$/N;/\n$/D' "$SSH_CONFIG_FILE.tmp"

        # Use sed to remove leading and trailing blank lines
        sed -i.bak '/./,$!d' "$SSH_CONFIG_FILE.tmp" # Remove leading blank lines

        # Remove the backup file created by sed
        rm "$SSH_CONFIG_FILE.tmp.bak"

        # Replace the original config file with the modified one
        mv "$SSH_CONFIG_FILE.tmp" "$SSH_CONFIG_FILE"

    fi
}

trap cleanup EXIT

echo "Attempting to install $GITHUB_HOSTNAME/$REPO_URL on this computer..."

# Check if the clone directory exists and is a Git repository
if [ -d "$CLONE_DIR" ] && [ -d "$CLONE_DIR/.git" ]; then
    echo "Directory $CLONE_DIR already exists and is a Git repository. Exiting."
    exit 1
fi

# Check if the GitHub CLI is installed
if ! command -v gh &>/dev/null; then
    echo "GitHub CLI (gh) could not be found. Please install it and try again."
    exit 1
fi

# Check if SSH configuration already exists for the exact key name
if [ -f "$KEY_PATH" ] && [ -f "$KEY_PATH.pub" ]; then
    echo "Using the github.com SSH key that already exists."
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
echo "Enter a title for your SSH key (e.g. 'Work Laptop' or 'Personal Laptop'):"
read -r TITLE

# Add SSH key to GitHub
if ! gh ssh-key add "$KEY_PATH.pub" -t "$TITLE"; then
    echo "Failed to add SSH key to GitHub. Please check the above error message and try again."
    exit 1
fi

SSH_CONFIG_CLEANUP_REQUIRED=false
echo "SSH key successfully added to GitHub."

# Create the directory for cloning if it doesn't exist
mkdir -p "$CLONE_DIR"

# Clone the repository using gh
echo "Cloning repository $REPO_URL into $CLONE_DIR..."

if ! gh repo clone "$REPO_URL" "$CLONE_DIR"; then
    echo "Failed to clone $REPO_URL. Please check the above error message and try again."
    exit 1
fi

gh auth logout

echo "Repository successfully cloned."
