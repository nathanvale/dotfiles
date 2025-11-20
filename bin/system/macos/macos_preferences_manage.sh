#!/bin/bash

set -e

# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

PREFERENCES_SCRIPT="$0"
dry_run=false
action=""

usage() {
    echo "Usage: $0 [-s | --set] [-r | --reset] [-d | --dry] [-h | --help]"
    echo "  -s, --set     : Set macOS preferences"
    echo "  -r, --reset   : Reset macOS preferences to default"
    echo "  -d, --dry     : Show what would be done without making changes (must be used with --set or --reset)"
    echo "  -h, --help    : Display this help message"
}

quote_params() {
    local result=""
    for param in "$@"; do
        # Check if the parameter contains spaces, indicating it needs quotes
        if [[ "$param" =~ \  ]]; then
            result="$result\"$param\" "
        else
            result="$result$param "
        fi
    done
    echo "$result"
}

apply_preference() {
    local quoted_params
    quoted_params=$(quote_params "$@")
    if $dry_run; then
        "log $INFO ""Would set $quoted_params"
    else
        "log $INFO ""Setting $quoted_params"
        sudo defaults write "$@"
    fi
}

set_preferences() {

    if $dry_run; then
        "log $WARNING ""Dry run is enabled. Skipping setting preferences."
    else
        "log $INFO ""Setting macOS preferences..."
    fi

    # Activity Monitor
    apply_preference com.apple.ActivityMonitor OpenMainWindow -bool true     # Show the main window when launching Activity Monitor
    apply_preference com.apple.ActivityMonitor ShowCategory -int 0           # Show all processes in Activity Monitor
    apply_preference com.apple.ActivityMonitor SortColumn -string "CPUUsage" # Sort Activity Monitor results by CPU usage
    apply_preference com.apple.ActivityMonitor SortDirection -int 0          # Set sort direction to descending in Activity Monitor

    # Apple Global Domain

    apply_preference NSGlobalDomain NSQuitAlwaysKeepsWindows -bool true              # Disable resume system-wide
    apply_preference NSGlobalDomain AppleInterfaceStyle -string "Dark"               # Enable Dark Mode
    apply_preference NSGlobalDomain AppleKeyboardUIMode -int 2                       # Enable full keyboard access for all controls (e.g., enable Tab in modal dialogs)
    apply_preference NSGlobalDomain ApplePressAndHoldEnabled -bool false             # Disable press-and-hold for keys in favor of key repeat
    apply_preference NSGlobalDomain AppleShowAllExtensions -bool true                # Show all filename extensions
    apply_preference NSGlobalDomain KeyRepeat -int 1                                 # Set a blazingly fast keyboard repeat rate
    apply_preference NSGlobalDomain InitialKeyRepeat -int 10                         # Set a short delay until key repeat
    apply_preference NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false     # Disable automatic capitalization as it’s annoying when typing code
    apply_preference NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false   # Disable smart dashes as they’re annoying when typing code
    apply_preference NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false # Disable automatic period substitution as it’s annoying when typing code
    apply_preference NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false  # Disable smart quotes as they’re annoying when typing code
    apply_preference NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false # Disable auto-correct
    apply_preference NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false    # Save to disk (not to iCloud) by default
    apply_preference NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true    # Expand save panel by default
    apply_preference NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true   # Expand save panel by default
    apply_preference NSGlobalDomain NSWindowResizeTime -float 0.001                  # Speed up window resize animations
    apply_preference NSGlobalDomain NSDisableAutomaticTermination -bool true         # Disable automatic termination of inactive apps
    apply_preference NSGlobalDomain WebKitDeveloperExtras -bool true                 # Enable WebKit developer tools

    # Bluetooth Audio
    apply_preference com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 48 # Increase sound quality for Bluetooth headphones/headsets

    # Crash Reporter
    apply_preference com.apple.CrashReporter DialogType -string "none" # Disable the crash reporter

    # Desktop Services
    apply_preference com.apple.desktopservices DSDontWriteNetworkStores -bool true # Avoid creating .DS_Store files on network or USB volumes
    apply_preference com.apple.desktopservices DSDontWriteUSBStores -bool true     # Avoid creating .DS_Store files on network or USB volumes

    # Disk Images
    apply_preference com.apple.frameworks.diskimages auto-open-ro-root -bool true  # Automatically open a new Finder window when a volume is mounted
    apply_preference com.apple.frameworks.diskimages auto-open-rw-root -bool true  # Automatically open a new Finder window when a volume is mounted
    apply_preference com.apple.frameworks.diskimages skip-verify -bool true        # Disable disk image verification
    apply_preference com.apple.frameworks.diskimages skip-verify-locked -bool true # Disable disk image verification
    apply_preference com.apple.frameworks.diskimages skip-verify-remote -bool true # Disable disk image verification

    # Dock
    apply_preference com.apple.spaces "spans-displays" -bool "true"                    # Disable displays have seperate spaces
    apply_preference com.apple.dock "expose-group-apps" -bool "true"                   # Group windows by application in Mission Control
    apply_preference com.apple.dock autohide -bool true                                # Automatically hide and show the Dock
    apply_preference com.apple.dock autohide-time-modifier -float 0.001                # Speed up Dock auto-hide/show animation
    apply_preference com.apple.dock enable-spring-load-actions-on-all-items -bool true # Enable spring loading for all Dock items
    apply_preference com.apple.dock expose-animation-duration -float 0.1               # Speed up Mission Control animations
    apply_preference com.apple.dock launchanim -bool false                             # Disable animation when opening applications from the Dock
    apply_preference com.apple.dock mineffect -string "scale"                          # Change minimize/maximize window effect to scale
    apply_preference com.apple.dock minimize-to-application -bool true                 # Minimize windows into their application’s icon
    apply_preference com.apple.dock mouse-over-hilite-stack -bool true                 # Enable highlight hover effect for the grid view of a stack (Dock)
    apply_preference com.apple.dock persistent-apps -array                             # Clear all default app icons from the Dock
    apply_preference com.apple.dock show-process-indicators -bool true                 # Show indicator lights for open applications in the Dock
    apply_preference com.apple.dock showhidden -bool true                              # Make Dock icons of hidden applications translucent
    apply_preference com.apple.dock showLaunchpadGestureEnabled -int 0                 # Disable the Launchpad gesture (pinch with thumb and three fingers)
    apply_preference com.apple.dock static-only -bool true                             # Show only open applications in the Dock
    apply_preference com.apple.dock tilesize -int 16                                   # Set the icon size of Dock items to 16 pixels
    apply_preference com.apple.dock "show-recents" -bool false                         # Do not display recent apps in the Dock
    apply_preference com.apple.dock "mru-spaces" -bool false                           # Keep the Spaces arrangement in the order it was set
    apply_preference com.apple.dock wvous-tl-corner -int 4                             # Configure hot corners: Top left screen corner → Desktop
    apply_preference com.apple.dock wvous-tl-modifier -int 1048576
    apply_preference com.apple.dock wvous-tr-corner -int 4 # Configure hot corners: Top right screen corner → Desktop
    apply_preference com.apple.dock wvous-tr-modifier -int 1048576
    apply_preference com.apple.dock wvous-bl-corner -int 5 # Configure hot corners: Bottom left screen corner → Start screen saver
    apply_preference com.apple.dock wvous-bl-modifier -int 1048576
    apply_preference com.apple.dock wvous-br-corner -int 10 # Configure hot corners: Bottom right screen corner → Put display to sleep
    apply_preference com.apple.dock wvous-br-modifier -int 1048576

    # Finder
    apply_preference com.apple.finder FXDefaultSearchScope -string "SCcf"        # Search the current folder by default when performing a search
    apply_preference com.apple.finder FXEnableExtensionChangeWarning -bool false # Disable the warning when changing a file extension
    apply_preference com.apple.finder FXInfoPanesExpanded -dict \
        General -bool true \
        OpenWith -bool true \
        Privileges -bool true                                                      # Expand General, Open With, and Privileges panes in Finder Info windows
    apply_preference com.apple.finder FXPreferredViewStyle -string "clmv"          # Use column view in all Finder windows by default
    apply_preference com.apple.finder NewWindowTarget -string "PfHm"               # Set Desktop as the default location for new Finder windows
    apply_preference com.apple.finder NewWindowTargetPath -string "file://${HOME}" # Set Desktop as the default location for new Finder windows
    apply_preference com.apple.finder OpenWindowForNewRemovableDisk -bool true     # Automatically open a new Finder window when a removable disk is mounted
    apply_preference com.apple.finder QuitMenuItem -bool false                     # Enable quitting via ⌘ + Q; doing so will also hide desktop icons
    apply_preference com.apple.finder ShowExternalHardDrivesOnDesktop -bool true   # Show icons for external hard drives, servers, and removable media on the desktop
    apply_preference com.apple.finder ShowHardDrivesOnDesktop -bool false
    apply_preference com.apple.finder ShowMountedServersOnDesktop -bool false
    apply_preference com.apple.finder ShowPathbar -bool true
    apply_preference com.apple.finder ShowRemovableMediaOnDesktop -bool true
    apply_preference com.apple.finder _FXShowPosixPathInTitle -bool true # Display full POSIX path as Finder window title
    apply_preference com.apple.finder _FXSortFoldersFirst -bool true     # Keep folders on top when sorting by name
    apply_preference com.apple.finder QLEnableTextSelection -bool true   # Allow text selection in Quick Look

    # Help Viewer
    apply_preference com.apple.helpviewer DevMode -bool true # Set Help Viewer windows to non-floating mode

    # Mail
    apply_preference com.apple.mail AddressesIncludeNameOnPasteboard -bool false # Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app

    # Printing
    apply_preference NSGlobalDomain PMPrintingExpandedStateForPrint -bool true  # Expand print panel by default
    apply_preference NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true # Expand print panel by default

    # Safari
    apply_preference com.apple.Safari UniversalSearchEnabled -bool false                # Disable sending search queries to Apple
    apply_preference com.apple.Safari SuppressSearchSuggestions -bool true              # Disable sending search queries to Apple
    apply_preference com.apple.Safari WebContinuousSpellCheckingEnabled -bool true      # Enable continuous spellchecking
    apply_preference com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false # Disable auto-correct
    apply_preference com.apple.Safari HomePage -string "about:blank"                    # Set Safari’s home page to `about:blank` for faster loading
    apply_preference com.apple.Safari AutoOpenSafeDownloads -bool false                 # Prevent Safari from opening ‘safe’ files automatically after downloading

    # Add other settings here...

    if ! $dry_run; then
        # Kill affected applications
        killall Dock
        killall Finder
        killall SystemUIServer
        "log $INFO ""macOS preferences set."
    fi

}

reset_preferences() {
    if $dry_run; then
        "log $WARNING ""Dry run is enabled. Skipping resetting preferences."
    else
        "log $INFO ""Resetting macOS preferences to default..."
    fi

    while IFS= read -r line; do
        # Extract the domain
        domain=$(echo "$line" | awk '{print $2}')

        # Extract the key and value pair, respecting quotes and stopping at the first complete quoted value
        key_and_value=$(echo "$line" | awk 'match($0, /apply_preference [^ ]* /){print substr($0, RSTART + RLENGTH)}' | sed -E 's/("[^"]*"|[^ ]*).*/\1/')
        if [[ -n "$domain" && -n "$key_and_value" ]]; then
            if $dry_run; then
                "log $INFO ""Would reset $domain $key_and_value"
            else
                if eval "defaults read $domain $key_and_value" &>/dev/null; then
                    "log $INFO ""Resetting $domain $key_and_value."
                    eval "defaults delete $domain $key_and_value"
                else
                    "log $WARNING ""$domain $key_and_value already reset"
                fi
            fi
        fi
    done < <(grep -o '^\s*apply_preference [^ ]* [^ ]*.*' "$PREFERENCES_SCRIPT")

    if ! $dry_run; then
        # Kill affected applications
        killall Dock
        killall Finder
        killall SystemUIServer
        "log $INFO ""macOS preferences reset to default"
    fi

}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
    -s | --set)
        action="set"
        shift
        ;;
    -r | --reset)
        action="reset"
        shift
        ;;
    -d | --dry)
        dry_run=true
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        usage
        exit 1
        ;;
    esac
done

if [[ "$dry_run" == true && -z "$action" ]]; then
    "log $ERROR ""--dry must be used with --set or --reset"
    usage
    exit 1
fi

if [[ -z "$action" ]]; then
    usage
    exit 1
fi

osascript -e 'tell application "System Preferences" to quit'

# # Ask for the administrator password upfront
# sudo -v

# # Keep-alive: update existing `sudo` time stamp until this script has finished
# while true; do
#     sudo -n true
#     sleep 60
#     kill -0 "$$" || exit
# done 2>/dev/null &

case $action in
set)
    set_preferences
    ;;
reset)
    reset_preferences
    ;;
*)
    usage
    exit 1
    ;;
esac
