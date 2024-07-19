#!/bin/bash

set -e

# Variables
KEY_NAME="id_rsa_github"
KEY_COMMENT="hi@nathanvale.com"
SSH_CONFIG_FILE="$HOME/.ssh/config"
GITHUB_HOSTNAME="github.com"
GITHUB_SCOPES="admin:public_key,admin:ssh_signing_key"

echo "Attempting to add your SSH key to GitHub..."

# Check if the GitHub CLI is installed
if ! command -v gh &>/dev/null; then
    echo "GitHub CLI (gh) could not be found. Please install it and try again."
    exit 1
fi

# Check if SSH configuration already exists
if grep -q "IdentityFile ~/.ssh/$KEY_NAME" "$SSH_CONFIG_FILE" &>/dev/null; then
    echo "A github.com SSH key already exists in $SSH_CONFIG_FILE. Exiting script."
    exit 1
fi

# Generate SSH key
ssh-keygen -t rsa -b 4096 -C "$KEY_COMMENT" -f "$HOME/.ssh/$KEY_NAME" -q -N ""

# Determine whether to use login or refresh
if gh auth status &>/dev/null; then
    gh auth refresh --hostname "$GITHUB_HOSTNAME" --scopes "$GITHUB_SCOPES"
else
    gh auth login --hostname "$GITHUB_HOSTNAME" --web --git-protocol ssh --skip-ssh-key --scopes "$GITHUB_SCOPES"
fi

echo "Enter a title for your SSH key (e.g. 'Work Laptop' or 'Personal Laptop'):"
read -r TITLE

# Add SSH key to GitHub
if ! gh ssh-key add "$HOME/.ssh/${KEY_NAME}.pub" -t "$TITLE"; then
    echo "Failed to add SSH key to GitHub. Please check the above error message and try again."
    exit 1
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
ssh-add "$HOME/.ssh/$KEY_NAME"

echo "SSH key successfully added to GitHub and SSH agent."
