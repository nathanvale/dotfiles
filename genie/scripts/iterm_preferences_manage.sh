#!/bin/bash

set -e

# Directory to save or load settings
SETTINGS_DIR="$HOME/code/dotfiles/misc/iterm2"
FILE_NAME="iterm2_settings.plist"
FILE_PATH="$SETTINGS_DIR/$FILE_NAME"

# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

# Usage function
usage() {
    echo "Usage: $0 [-e | --export] [-i | --import] [-d | --delete] [-h | --help]"
    echo ""
    echo "Options:"
    echo "  -e, --export    Export iTerm2 settings to $FILE_PATH"
    echo "  -i, --import    Import iTerm2 settings from $FILE_PATH"
    echo "  -d, --delete    Delete iTerm2 settings from defaults"
    echo "  -h, --help      Display this help message"
    echo ""
    echo "Example:"
    echo "  $0 --export"
    echo "  $0 --import"
    echo "  $0 --delete"
    exit 1
}

# Function to export iTerm2 settings
export_settings() {
    mkdir -p "$SETTINGS_DIR"
    defaults export com.googlecode.iterm2 "$FILE_PATH"
    if [ $? -eq 0 ]; then
        log $INFO "iTerm2 settings exported successfully to $FILE_PATH."
        exit 0
    else
        log $ERROR "Failed to export iTerm2 settings."
        exit 1
    fi
}

# Function to import iTerm2 settings
import_settings() {
    defaults import com.googlecode.iterm2 "$FILE_PATH"
    if [ $? -eq 0 ]; then
        log $INFO "iTerm2 settings imported successfully from $FILE_PATH."
        echo "Please restart iTerm2 to apply changes."
        exit 0
    else
        log $ERROR "Failed to import iTerm2 settings."
        exit 1
    fi
}

# Function to delete iTerm2 settings from defaults
delete_settings() {
    defaults delete com.googlecode.iterm2
    if [ $? -eq 0 ]; then
        log $INFO "iTerm2 settings deleted from defaults successfully."
        exit 0
    else
        log $ERROR "Failed to delete iTerm2 settings from defaults."
        exit 1
    fi
}

# Check if no arguments are provided
if [ $# -eq 0 ]; then
    usage
fi

# Parse command-line arguments
while [[ "$1" != "" ]]; do
    case $1 in
    -e | --export)
        export_settings
        ;;
    -i | --import)
        import_settings
        ;;
    -d | --delete)
        delete_settings
        ;;
    -h | --help)
        usage
        ;;
    *)
        usage
        ;;
    esac
    shift
done
