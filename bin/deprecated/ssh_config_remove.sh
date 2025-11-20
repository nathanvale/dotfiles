#!/bin/bash

set -e

# Resolve the absolute path of the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/colour_log.sh"

normalize_ssh_file() {
    local file=$1
    awk 'NF {sub(/^[ \t]+/, ""); sub(/[ \t]+$/, ""); print}' "$file" >"$file.tmp" && mv "$file.tmp" "$file"
}

# Function to format the SSH config file
format_ssh_file() {
    local file=$1
    awk '
    /^#[ \t]+/ { next }  # Skip comments
    /^Host[ \t]+/ { print $0; next }  # Print lines starting with Host followed by spaces/tabs as they are
    {
        # Ensure only one space between config key and value
        sub(/[ \t]+/, " ", $0)
        print "  " $0  # Add two spaces to all other lines
    }
    ' "$file" >tmpfile && mv tmpfile "$file"
}

ssh_config_remove() {
    local host_to_remove=$1
    local ssh_config_file=$2

    if [ -f "$ssh_config_file" ]; then
        # Normalize the SSH config file first
        normalize_ssh_file "$ssh_config_file"

        # Use awk to delete lines from 'Host  host_to_remove' to the next 'Host' or end of file
        awk -v host="$host_to_remove" '
            BEGIN { delete_block = 0 }
            /^Host[ \t]+/ {
                # Check if the hostname matches, considering multiple spaces or tabs
                split($0, parts, "[ \t]+")
                delete_block = (parts[2] == host) ? 1 : 0
            }
            !delete_block' "$ssh_config_file" >tmpfile && mv tmpfile "$ssh_config_file"
        "log $INFO ""Removed host configuration for '$host_to_remove' from '$ssh_config_file'."

        normalize_ssh_file "$ssh_config_file"
        format_ssh_file "$ssh_config_file"
        "log $INFO ""Removed host configuration for '$host_to_remove' from '$ssh_config_file'."
    else
        "log $WARNING ""SSH configuration file '$ssh_config_file' not found."
    fi
}
