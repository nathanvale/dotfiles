KEY_NAME="id_rsa_github"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
SSH_CONFIG_FILE="$HOME/.ssh/config"
GITHUB_HOSTNAME="github.com"

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

remove_git_sha_from_ssh_config

# Sample SSH config file for testing
# Host github.com
#     AddKeysToAgent yes
#     UseKeychain yes
#     IdentityFile ~/.ssh/id_rsa_github

# Host github.com1
#     AddKeysToAgent yes
#     UseKeychain yes
#     IdentityFile ~/.ssh/id_rsa_github1

# Host github.com2
#     AddKeysToAgent yes
#     UseKeychain yes
#     IdentityFile ~/.ssh/id_rsa_github2
