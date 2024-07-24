#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define the URLs of the scripts to download in the required order
script_urls=(
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/brew_install.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/brew_bundle.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/dotfiles_install.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/manage_symlinks.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/macos_preferences.sh"
)

tmp_dir="/tmp/setup-scripts-$(date +%Y%m%d%H%M%S)"
mkdir -p "$tmp_dir"
echo "Scripts will be downloaded to $tmp_dir"

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
        echo "Failed to download $url (status code: $status_code)"
        cleanup
        exit 1
    fi

    # Make the script executable
    chmod +x "$tmp_file"
}

# Cleanup function to delete the temporary directory
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$tmp_dir"
}
# Register the cleanup function to be called on exit and on specific signals
trap cleanup HUP INT QUIT TERM

# Export GITHUB_TOKEN variable to be available for the child processes
export GITHUB_TOKEN

# Download each script
for url in "${script_urls[@]}"; do
    download_scripts "$url"
done

# Create run_downloaded_scripts.sh script
run_script="$tmp_dir/run_downloaded_scripts.sh"
cat <<EOF >"$run_script"
#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Cleanup function to delete the temporary directory
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$tmp_dir"
}
# Register the cleanup function to be called on exit and on specific signals
trap cleanup EXIT HUP INT QUIT TERM

# Execute each script in the order they were downloaded
script_names=(
    $(for url in "${script_urls[@]}"; do echo "\"$(basename "$url")\""; done | tr '\n' ' ')
)

tmp_dir="$tmp_dir"

# Iterate over the script names and execute each
for script in "\${script_names[@]}"; do
    script_path="\$tmp_dir/\$script"
    if [[ -x "\$script_path" ]]; then
        echo "Executing \$script_path"
        "\$script_path"
    else
        echo "Script \$script_path is not executable or not found."
        exit 1
    fi
done


echo "All scripts executed successfully."
EOF

# Make the run_downloaded_scripts.sh script executable
chmod +x "$run_script"

# Inform the user how to run the scripts
echo "All scripts downloaded to $tmp_dir"
echo "To execute the scripts, run:"
echo "$run_script"
