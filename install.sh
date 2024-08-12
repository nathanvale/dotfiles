#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Set the directory where scripts should be saved
tmp_dir="/tmp/genie-$(date +%Y%m%d%H%M%S)"

# Register the cleanup function to be called on exit and on specific signals
trap cleanup HUP INT QUIT TERM

# Cleanup function to delete the temporary directory
cleanup() {
    rm -rf /tmp/genie-*
    if ! rm -rf "$tmp_dir"; then
        echo "Failed to remove the temporary directory $tmp_dir"
    else
        echo "Removed the temporary directory $tmp_dir"
    fi
}

download_script() {
    local url=$1
    local folder=$2
    local tmp_file="$tmp_dir/$folder/$(basename "$url")"

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

cleanup

# Create the application directory
mkdir -p "$tmp_dir"
mkdir -p "$tmp_dir/scripts"
mkdir -p "$tmp_dir/bin"

# Export GITHUB_TOKEN variable to be available for the child processes
export GITHUB_TOKEN

download_script https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/colour_log.sh scripts
download_script https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/ssh_config_remove.sh scripts
download_script https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/macos_preferences_manage.sh scripts
download_script https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/nerd_fonts_manage.sh scripts
download_script https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/symlinks_manage.sh scripts
download_script https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/yabai_sa_manage.sh scripts
download_script https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/installation_scripts.sh scripts
download_script https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/uninstallation_scripts.sh scripts
download_script https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/bin/genie bin

source "$tmp_dir/scripts/colour_log.sh"
source "$tmp_dir/scripts/installation_scripts.sh"
source "$tmp_dir/scripts/uninstallation_scripts.sh"

# Download each script and save it to the scripts sub directory
for url in "${installation_urls[@]}"; do
    download_script "$url" scripts
done

# Add $tmp_dir/bin to the PATH
export PATH="$PATH:$tmp_dir/bin"

# Inform the user how to run the scripts
echo "All scripts downloaded to $tmp_dir"
echo "To execute the scripts, run:"
echo "genie --install"
