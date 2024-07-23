#!/bin/bash

# Define the URLs of the scripts to download
scripts=(
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/create_dotfiles_symlinks.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/bin/hello_world.sh"
)

# Create a temporary directory to store the downloaded scripts
tmp_dir=$(mktemp -d)

# Function to download and execute scripts
download_and_execute() {
    local url=$1
    local tmp_file="$tmp_dir/$(basename "$url")"

    # Download the script
    echo "Downloading $url..."
    curl -H "Authorization: token $TOKEN" -s -o "$tmp_file" "$url"

    # Make the script executable
    chmod +x "$tmp_file"

    # Execute the script
    echo "Executing $tmp_file..."
    "$tmp_file"
}

# Iterate over the scripts array and process each script
for script_url in "${scripts[@]}"; do
    download_and_execute "$script_url"
done

# Cleanup: remove the temporary directory
rm -rf "$tmp_dir"

echo "All scripts executed successfully."
