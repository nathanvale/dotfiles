#!/bin/bash

# Define the URLs of the scripts to download and their respective parameters
scripts=(
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/check_shell.sh|"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/brew_install.sh|"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/brew_bundle.sh|"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/dotfiles.sh|"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/manage_symlinks.sh|"
)

# Create a temporary directory to store the downloaded scripts
tmp_dir=$(mktemp -d)

# Function to download and execute scripts
download_and_execute() {
    local url=$1
    local params=$2
    local tmp_file="$tmp_dir/$(basename "$url")"

    # Determine whether to use the Authorization header
    if [ -n "$GITHUB_TOKEN" ]; then
        auth_header="Authorization: token $GITHUB_TOKEN"
    else
        auth_header=""
    fi

    # Download the script
    echo "Downloading $url..."
    if [ -n "$auth_header" ]; then
        status_code=$(curl -w "%{http_code}" -H "$auth_header" -s -o "$tmp_file" "$url")
    else
        status_code=$(curl -w "%{http_code}" -s -o "$tmp_file" "$url")
    fi

    # Check if the download was successful
    if [ "$status_code" -ne 200 ]; then
        echo "Failed to download $url (status code: $status_code)"
        return 1
    fi

    # Make the script executable
    chmod +x "$tmp_file"

    # Execute the script with parameters if provided
    if [ -n "$params" ]; then
        echo "Executing $tmp_file with params: $params"
        "$tmp_file" $params
    else
        echo "Executing $tmp_file without params"
        "$tmp_file"
    fi
}

# Export GITHUB_TOKEN variable to be available for the child processes
export GITHUB_TOKEN

# Iterate over the scripts array and process each script with its parameters
for entry in "${scripts[@]}"; do
    url="${entry%%|*}"
    params="${entry##*|}"
    download_and_execute "$url" "$params"
done

# Cleanup: remove the temporary directory
rm -rf "$tmp_dir"

echo "All scripts executed successfully."
