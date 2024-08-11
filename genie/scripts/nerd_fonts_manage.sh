#!/bin/bash

set -e

# Directory containing the fonts
FONT_DIR="$HOME/code/dotfiles/misc/mesloLGS_NF"
DEST_DIR="$HOME/Library/Fonts"

# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

# Function to display usage
usage() {
    echo "Usage: $0 [-a | --add] [-r | --remove] [-h | --help]"
    echo "  -a, --add     Add nerd fonts"
    echo "  -r, --remove  Remove nerd fonts"
    echo "  -h, --help    Display this help message"
    exit 1
}

# Function to add fonts
add_fonts() {
    mkdir -p "$DEST_DIR"
    cp "$FONT_DIR"/*.ttf "$DEST_DIR"
    if [ $? -eq 0 ]; then
        echo "Nerd fonts added successfully."
        log $INFO "Nerd fonts added successfully."
        exit 0
    else
        log $ERROR "Failed to add nerd fonts."
        exit 1
    fi
}

# Function to remove fonts
remove_fonts() {
    rm -f "$DEST_DIR"/mesloLGS_NF_*.ttf
    if [ $? -eq 0 ]; then
        log $INFO "Nerd fonts removed successfully."
        exit 0
    else
        log $ERROR "Failed to remove nerd fonts."
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
    -a | --add)
        shift
        add_fonts
        ;;
    -r | --remove)
        shift
        remove_fonts
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
