#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# URL of the common.sh script
common_url="https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/common.sh"
run_script_url="https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/run_downloaded_scripts.sh"

# Define the URLs of the uninstall scripts to download in the required order
uninstall_script_urls=(
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/colour_log.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/check_shell.sh"
)

# Remove the existing uninstall_dotfiles script
sudo rm -f /usr/local/bin/uninstall_dotfiles

# Remove the existing temporary directory /tmp/setup-scripts-*
rm -rf /tmp/setup-scripts-*

tmp_dir="/tmp/setup-scripts-$(date +%Y%m%d%H%M%S)"
mkdir -p "$tmp_dir"

# Download common.sh
curl -H "Authorization: token $GITHUB_TOKEN" -s -o "$tmp_dir/common.sh" "$common_url"

# Source common.sh
source "$tmp_dir/common.sh"

# Export GITHUB_TOKEN variable to be available for the child processes
export GITHUB_TOKEN

# Download each uninstall script
for url in "${uninstall_script_urls[@]}"; do
    download_scripts "$url"
done

# Write the uninstall_script_urls array to a temporary file
echo "script_urls=(" >"$tmp_dir/script_urls.sh"
for url in "${uninstall_script_urls[@]}"; do
    echo "\"$url\"" >>"$tmp_dir/script_urls.sh"
done
echo ")" >>"$tmp_dir/script_urls.sh"

# Download the run_downloaded_scripts.sh
curl -H "Authorization: token $GITHUB_TOKEN" -s -o "$tmp_dir/run_downloaded_scripts.sh" "$run_script_url"
chmod +x "$tmp_dir/run_downloaded_scripts.sh"

# Create a symbolic link for run_uninstall_scripts.sh
sudo ln -sf "$tmp_dir/run_downloaded_scripts.sh" /usr/local/bin/uninstall_dotfiles

# Inform the user how to run the uninstall scripts
echo "All uninstall scripts downloaded to $tmp_dir"
echo "To execute the uninstall scripts, run:"
echo "uninstall_dotfiles"
