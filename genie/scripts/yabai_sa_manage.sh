#!/bin/bash

# https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(from-HEAD)#configure-scripting-addition

set -e

# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

plist_destination="${HOME}/Library/LaunchAgents/com.yabai.loadsa.plist"

# Function to display usage
usage() {
    echo "Usage: $0 [-c | --configure] [-u | --unconfigure] [-h | --help]"
    echo "  -c, --configure  Configure yabai to load scripting addition"
    echo "  -u, --unconfigure Unconfigure yabai to load scripting addition"
    echo "  -h, --help         Display this help message"
    exit 1
}

# Function to write and load plist
write_plist() {
    remove_plist
    cat <<EOF >"$plist_destination"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.yabai.loadsa</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/sudo</string>
        <string>/opt/homebrew/bin/yabai</string>
        <string>--load-sa</string>
        <string>--start-service</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/com.yabai.loadsa.out.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/com.yabai.loadsa.err.log</string>
</dict>
</plist>
EOF
    log $INFO "Configuring your user to execute yabai --load-sa as the root user without having to enter a password..."
    echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai
    log $INFO "com.yabai.loadsa plist  written to: $plist_destination"
    launchctl load "$plist_destination"
    log $INFO "com.yabai.loadsa plist loaded via launchctl"
}

# Function to remove and unload plist
remove_plist() {
    if [ -f "/private/etc/sudoers.d/yabai" ]; then
        log $INFO "Removing yabai sudoers entry..."
        sudo rm /private/etc/sudoers.d/yabai
        log $INFO "yabai sudoers entry removed"
    fi
    if [ -f "$plist_destination" ]; then
        launchctl unload "$plist_destination"
        log $INFO "com.yabai.loadsa plistunloaded via launchctl"
        rm "$plist_destination"
        log $INFO "com.yabai.loadsa plist removed: $plist_destination"
    fi
}

# Main execution
if [ $# -eq 0 ]; then
    usage
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
    -c | --configure)
        write_plist
        shift
        ;;
    -u | --unconfigure)
        remove_plist
        shift
        ;;
    -h | --help)
        usage
        ;;
    *)
        usage
        ;;
    esac
done
