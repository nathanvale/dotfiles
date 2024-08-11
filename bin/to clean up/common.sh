#!/bin/bash

# Function to download scripts
download_scripts() {
    local url=$1
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
        message="Failed to download $url (status code: $status_code)"
        echo -e "\033[0;31m$message\033[0m"
        # Check if the GITHUB_TOKEN environment variable is not set
        if [ -z "$auth_header" ]; then
            echo "Make sure to set the GITHUB_TOKEN environment variable if $url exists in a private repo."
            echo "For public repos, you can ignore this message."
            echo "export GITHUB_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        fi
        cleanup
        exit 1
    fi

    # Make the script executable
    chmod +x "$tmp_file"
}

# Cleanup function to delete the temporary directory
cleanup() {
    rm -rf "$tmp_dir"
}

# Register the cleanup function to be called on exit and on specific signals
trap cleanup HUP INT QUIT TERM
