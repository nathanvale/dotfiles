#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "This script will install the genie application on your system."

# Set the directory where scripts should be saved
tmp_dir="/tmp/genie-$(date +%Y%m%d%H%M%S)"

# Cleanup function to delete the temporary directory
cleanup() {
    rm -rf /tmp/genie-*
}

# Function to download scripts
download_script() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: download_script <url> <folder>"
        exit 1
    fi
    local url=$1
    local folder=$2
    local tmp_file="$tmp_dir/$folder/$(basename "$url")"
    status_code=$(curl -w "%{http_code}" -s -o "$tmp_file" "$url")
    chmod +x "$tmp_file"
}

cleanup

# Create the application directory
mkdir -p "$tmp_dir"

# Export GITHUB_TOKEN variable to be available for the child processes
export GITHUB_TOKEN

download_script https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/color_log.sh scripts
download_script https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/installation_scripts.sh scripts
download_script https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/uninstallation_scripts.sh scripts
download_script https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/genie bin

# Register the cleanup function to be called on exit and on specific signals
trap cleanup HUP INT QUIT TERM

source "$tmp_dir/scripts/color_log.sh"
source "$tmp_dir/scripts/installation_scripts.sh"
source "$tmp_dir/scripts/uninstallation_scripts.sh"

# Download each script and save it to the scripts sub directory
for url in "${installation_urls[@]}"; do
    download_script "$url" scripts
done

if ! $tmp_dir/bin/genie --install; then
    cleanup
    exit 1
fi
