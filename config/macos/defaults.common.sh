#!/usr/bin/env bash
# defaults.common.sh - macOS preferences for desktop (and base for server)
#
# Follows Mathias Bynens' dotfiles pattern:
#   - No sudo for user-domain settings (com.apple.*, NSGlobalDomain)
#   - Direct `defaults write` calls, organized by section
#   - Selective killall at the end
#
# Usage:
#   ./defaults.common.sh --set              # Apply all preferences
#   ./defaults.common.sh --reset            # Reset to macOS defaults
#   ./defaults.common.sh --set --dry-run    # Preview changes
#   ./defaults.common.sh --reset --dry-run  # Preview resets

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../bin/colour_log.sh"

DRY_RUN=false
ACTION=""
HAS_FDA=false

usage() {
    echo "Usage: $0 [--set | --reset] [--dry-run]"
    echo "  --set, -s      Apply macOS preferences"
    echo "  --reset, -r    Reset macOS preferences to defaults"
    echo "  --dry-run, -d  Preview changes (must combine with --set or --reset)"
    echo "  --help, -h     Show this help message"
}

# Run a defaults write command (respects dry-run)
run() {
    if $DRY_RUN; then
        log "$INFO" "[DRY-RUN] $*"
    else
        log "$INFO" "$*"
        eval "$@"
    fi
}

# Check if this terminal has Full Disk Access.
# Safari (and other sandboxed apps) store prefs in ~/Library/Containers/
# which is SIP-protected. Without FDA, `defaults write com.apple.Safari`
# silently writes to the wrong plist and Safari ignores it entirely.
# Detection: TimeMachine plist is FDA-protected -- if we can read it, we have FDA.
check_full_disk_access() {
    if plutil -lint /Library/Preferences/com.apple.TimeMachine.plist >/dev/null 2>&1; then
        HAS_FDA=true
    fi
}

set_preferences() {
    log "$INFO" "============================================"
    log "$INFO" "Applying common macOS preferences"
    log "$INFO" "============================================"
    if $DRY_RUN; then
        log "$WARNING" "DRY RUN MODE - No changes will be made"
    fi

    # Detect FDA early so we can report status upfront
    check_full_disk_access
    if $HAS_FDA; then
        log "$INFO" "Full Disk Access: YES (sandboxed app prefs will be applied)"
    else
        log "$WARNING" "Full Disk Access: NO (Safari prefs will be skipped)"
        log "$WARNING" "To fix: System Settings > Privacy & Security > Full Disk Access > add your terminal"
    fi

    # Close System Settings to prevent overriding our changes
    osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

    # ── Keyboard ──────────────────────────────────
    log "$INFO" ""
    log "$INFO" "=== Keyboard ==="

    run defaults write NSGlobalDomain KeyRepeat -int 1                                 # Blazingly fast repeat rate
    run defaults write NSGlobalDomain InitialKeyRepeat -int 10                         # Short delay until repeat
    run defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false             # Key repeat instead of accent menu
    run defaults write NSGlobalDomain AppleKeyboardUIMode -int 2                       # Full keyboard access (Tab in dialogs)
    run defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false      # No auto-capitalization
    run defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false    # No smart dashes
    run defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false  # No auto-period
    run defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false   # No smart quotes
    run defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false  # No auto-correct

    # ── Trackpad ──────────────────────────────────
    log "$INFO" ""
    log "$INFO" "=== Trackpad ==="

    run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true  # Tap to click
    run defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1           # Tap to click (current host)
    run defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1                        # Tap to click (global)

    # ── General UI ────────────────────────────────
    log "$INFO" ""
    log "$INFO" "=== General UI ==="

    run defaults write NSGlobalDomain AppleInterfaceStyle -string '"Dark"'                # Dark Mode
    run defaults write NSGlobalDomain AppleShowAllExtensions -bool true                   # Show all file extensions
    run defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool true                 # Resume windows on relaunch
    run defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false        # Save to disk, not iCloud
    run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true        # Expanded save panel
    run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true       # Expanded save panel (2)
    run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true           # Expanded print panel
    run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true          # Expanded print panel (2)
    run defaults write NSGlobalDomain NSWindowResizeTime -float 0.001                     # Fast window resize animation
    run defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false       # Disable window open/close animation
    run defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true             # Prevent auto-termination of apps
    run defaults write NSGlobalDomain WebKitDeveloperExtras -bool true                    # WebKit developer tools

    # ── Finder ────────────────────────────────────
    log "$INFO" ""
    log "$INFO" "=== Finder ==="

    run defaults write com.apple.finder FXPreferredViewStyle -string '"clmv"'              # Column view by default
    run defaults write com.apple.finder FXDefaultSearchScope -string '"SCcf"'              # Search current folder
    run defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false         # No extension change warning
    run defaults write com.apple.finder ShowPathbar -bool true                             # Show path bar
    run defaults write com.apple.finder ShowStatusBar -bool true                           # Show status bar
    run defaults write com.apple.finder _FXShowPosixPathInTitle -bool true                 # POSIX path in title
    run defaults write com.apple.finder _FXSortFoldersFirst -bool true                     # Folders on top
    run defaults write com.apple.finder QLEnableTextSelection -bool true                   # Text selection in Quick Look
    run defaults write com.apple.finder NewWindowTarget -string '"PfHm"'                   # New windows open home
    run 'defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"'     # New windows path
    run defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true           # Auto-open on removable disk
    run defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true          # External drives on desktop
    run defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false                # No internal drive icon
    run defaults write com.apple.finder ShowMountedServersOnDesktop -bool false             # No server icons
    run defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true             # Removable media on desktop
    run defaults write com.apple.finder WarnOnEmptyTrash -bool false                       # No trash warning
    run defaults write com.apple.finder QuitMenuItem -bool true                            # Allow Cmd+Q to quit Finder
    run 'defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true OpenWith -bool true Privileges -bool true'

    # ── Dock ──────────────────────────────────────
    log "$INFO" ""
    log "$INFO" "=== Dock ==="

    run defaults write com.apple.dock autohide -bool true                                 # Auto-hide Dock
    run defaults write com.apple.dock autohide-delay -float 0                             # Zero delay on auto-hide
    run defaults write com.apple.dock autohide-time-modifier -float 0.001                 # Fast auto-hide animation
    run defaults write com.apple.dock tilesize -int 16                                    # Small icon size (16px)
    run defaults write com.apple.dock mineffect -string '"scale"'                         # Scale minimize effect
    run defaults write com.apple.dock minimize-to-application -bool true                  # Minimize into app icon
    run defaults write com.apple.dock launchanim -bool false                              # No launch bounce
    run defaults write com.apple.dock show-process-indicators -bool true                  # Indicator dots for open apps
    run defaults write com.apple.dock showhidden -bool true                               # Translucent hidden app icons
    run defaults write com.apple.dock static-only -bool true                              # Only show open apps
    run defaults write com.apple.dock persistent-apps -array                              # Clear default pinned apps
    run defaults write com.apple.dock show-recents -bool false                            # No recent apps section
    run defaults write com.apple.dock mru-spaces -bool false                              # Don't reorder Spaces
    run defaults write com.apple.dock showLaunchpadGestureEnabled -int 0                  # No Launchpad gesture
    run defaults write com.apple.dock mouse-over-hilite-stack -bool true                  # Highlight stack on hover
    run defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true  # Spring loading for all items
    run defaults write com.apple.dock expose-animation-duration -float 0.1                # Fast Mission Control animation
    run 'defaults write com.apple.dock expose-group-apps -bool true'                      # Group windows by app
    run 'defaults write com.apple.spaces spans-displays -bool true'                       # Displays don't have separate Spaces

    # Hot corners: TL=Desktop, TR=Desktop, BL=Screen Saver, BR=Display Sleep
    run defaults write com.apple.dock wvous-tl-corner -int 4
    run defaults write com.apple.dock wvous-tl-modifier -int 1048576
    run defaults write com.apple.dock wvous-tr-corner -int 4
    run defaults write com.apple.dock wvous-tr-modifier -int 1048576
    run defaults write com.apple.dock wvous-bl-corner -int 5
    run defaults write com.apple.dock wvous-bl-modifier -int 1048576
    run defaults write com.apple.dock wvous-br-corner -int 10
    run defaults write com.apple.dock wvous-br-modifier -int 1048576

    # ── Screenshots ───────────────────────────────
    log "$INFO" ""
    log "$INFO" "=== Screenshots ==="

    run 'mkdir -p "${HOME}/Screenshots"'
    run 'defaults write com.apple.screencapture location -string "${HOME}/Screenshots"'   # Save to ~/Screenshots
    run defaults write com.apple.screencapture type -string '"png"'                       # PNG format
    run defaults write com.apple.screencapture disable-shadow -bool true                  # No window shadow
    run defaults write com.apple.screencapture include-date -bool true                    # Include date in filename

    # ── Desktop Services ──────────────────────────
    log "$INFO" ""
    log "$INFO" "=== Desktop Services ==="

    run defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true      # No .DS_Store on network volumes
    run defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true          # No .DS_Store on USB volumes

    # ── Disk Images ───────────────────────────────
    log "$INFO" ""
    log "$INFO" "=== Disk Images ==="

    run defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true       # Auto-open mounted volumes
    run defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true       # Auto-open mounted volumes
    run defaults write com.apple.frameworks.diskimages skip-verify -bool true             # Skip disk image verification
    run defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true      # Skip verification (locked)
    run defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true      # Skip verification (remote)

    # ── Activity Monitor ──────────────────────────
    log "$INFO" ""
    log "$INFO" "=== Activity Monitor ==="

    run defaults write com.apple.ActivityMonitor OpenMainWindow -bool true                # Show main window on launch
    run defaults write com.apple.ActivityMonitor ShowCategory -int 0                      # Show all processes
    run 'defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"'          # Sort by CPU usage
    run defaults write com.apple.ActivityMonitor SortDirection -int 0                     # Descending sort

    # ── Bluetooth Audio ───────────────────────────
    log "$INFO" ""
    log "$INFO" "=== Bluetooth Audio ==="

    run 'defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 48'  # Higher BT audio quality

    # ── Crash Reporter ────────────────────────────
    log "$INFO" ""
    log "$INFO" "=== Crash Reporter ==="

    run 'defaults write com.apple.CrashReporter DialogType -string "none"'                # Disable crash reporter dialog

    # ── Help Viewer ───────────────────────────────
    run defaults write com.apple.helpviewer DevMode -bool true                            # Non-floating Help windows

    # ── Mail ──────────────────────────────────────
    run defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false         # Copy email as address only

    # ── Safari (requires Full Disk Access) ───────
    log "$INFO" ""
    log "$INFO" "=== Safari ==="

    if $HAS_FDA || $DRY_RUN; then
        run defaults write com.apple.Safari UniversalSearchEnabled -bool false                # No search queries to Apple
        run defaults write com.apple.Safari SuppressSearchSuggestions -bool true              # No search suggestions
        run defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false # No auto-correct in Safari
        run 'defaults write com.apple.Safari HomePage -string "about:blank"'                  # Blank home page
        run defaults write com.apple.Safari AutoOpenSafeDownloads -bool false                 # No auto-open downloads (CIS benchmark)
    else
        log "$WARNING" "Safari prefs require Full Disk Access (5 settings: privacy, security, homepage)"
        log "$WARNING" ""
        log "$WARNING" "To fix:"
        log "$WARNING" "  1. Open: System Settings > Privacy & Security > Full Disk Access"
        log "$WARNING" "  2. Add your terminal app (Ghostty, Terminal, etc.)"
        log "$WARNING" "  3. Relaunch terminal and re-run this script"

        # In interactive mode, offer to pause so the user can go fix it now
        if [[ -t 0 ]] || [[ -e /dev/tty ]]; then
            local tty_input="/dev/tty"
            [[ -t 0 ]] && tty_input="/dev/stdin"

            echo ""
            log "$WARNING" "You can fix this now or skip and apply Safari prefs later."
            read -r -p "[p]ause to fix FDA now, or [s]kip? (p/s): " choice < "$tty_input"

            if [[ "$choice" =~ ^[Pp]$ ]]; then
                log "$INFO" ""
                log "$INFO" "Paused. Go grant Full Disk Access to your terminal, then relaunch it."
                log "$INFO" "Resume with: ./defaults.common.sh --set"
                exit 0
            fi
        fi

        log "$WARNING" "Skipping Safari prefs for now."
    fi

    # ── Network ───────────────────────────────────
    log "$INFO" ""
    log "$INFO" "=== Network ==="

    run defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true            # Browse all network interfaces

    # ── Developer Folders ─────────────────────────
    log "$INFO" ""
    log "$INFO" "=== Developer Folders ==="

    run chflags nohidden ~/Library                                                        # Show ~/Library folder

    # ── Restart Affected Apps ─────────────────────
    if ! $DRY_RUN; then
        log "$INFO" ""
        log "$INFO" "=== Restarting Affected Apps ==="
        for app in "Finder" "Dock" "SystemUIServer"; do
            killall "$app" 2>/dev/null || true
        done
        log "$INFO" ""
        log "$INFO" "============================================"
        if ! $HAS_FDA; then
            log "$WARNING" "macOS preferences applied (Safari skipped - no FDA)"
            log "$WARNING" ""
            log "$WARNING" "To apply Safari prefs:"
            log "$WARNING" "  1. System Settings > Privacy & Security > Full Disk Access"
            log "$WARNING" "  2. Add your terminal app (Ghostty, Terminal, etc.)"
            log "$WARNING" "  3. Relaunch terminal, then: ./defaults.common.sh --set"
        else
            log "$INFO" "macOS preferences applied successfully."
        fi
        log "$INFO" "============================================"
    else
        log "$INFO" ""
        log "$INFO" "============================================"
        log "$INFO" "Dry run complete - no changes made"
        log "$INFO" "============================================"
    fi
}

reset_preferences() {
    log "$INFO" "============================================"
    log "$INFO" "Resetting common macOS preferences"
    log "$INFO" "============================================"
    if $DRY_RUN; then
        log "$WARNING" "DRY RUN MODE - No changes will be made"
    fi

    # Parse this script for `defaults write` commands and issue `defaults delete` for each
    local script_path
    script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

    while IFS= read -r line; do
        # Extract domain and key from lines like:
        #   defaults write com.apple.dock autohide -bool true
        #   defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
        #   defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 48
        local domain key

        if [[ "$line" =~ defaults\ -currentHost\ write\ ([^ ]+)\ (\"[^\"]+\"|[^ ]+) ]]; then
            domain="${BASH_REMATCH[1]}"
            key="${BASH_REMATCH[2]}"
            if $DRY_RUN; then
                log "$INFO" "[DRY-RUN] defaults -currentHost delete $domain $key"
            else
                if defaults -currentHost read "$domain" "$key" &>/dev/null; then
                    log "$INFO" "Resetting (currentHost) $domain $key"
                    defaults -currentHost delete "$domain" "$key"
                else
                    log "$WARNING" "$domain $key already reset (currentHost)"
                fi
            fi
        elif [[ "$line" =~ defaults\ write\ ([^ ]+)\ (\"[^\"]+\"|[^ ]+) ]]; then
            domain="${BASH_REMATCH[1]}"
            key="${BASH_REMATCH[2]}"
            if $DRY_RUN; then
                log "$INFO" "[DRY-RUN] defaults delete $domain $key"
            else
                if defaults read "$domain" "$key" &>/dev/null; then
                    log "$INFO" "Resetting $domain $key"
                    defaults delete "$domain" "$key"
                else
                    log "$WARNING" "$domain $key already reset"
                fi
            fi
        fi
    done < <(grep -E '^\s+run .*(defaults write|defaults -currentHost write)' "$script_path")

    # Reverse chflags nohidden ~/Library
    if $DRY_RUN; then
        log "$INFO" "[DRY-RUN] chflags hidden ~/Library"
    else
        log "$INFO" "Hiding ~/Library"
        chflags hidden ~/Library
    fi

    if ! $DRY_RUN; then
        for app in "Finder" "Dock" "SystemUIServer"; do
            killall "$app" 2>/dev/null || true
        done
        log "$INFO" "macOS preferences reset to defaults."
    else
        log "$INFO" ""
        log "$INFO" "============================================"
        log "$INFO" "Dry run complete - no changes made"
        log "$INFO" "============================================"
    fi
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --set|-s)
            ACTION="set"
            shift
            ;;
        --reset|-r)
            ACTION="reset"
            shift
            ;;
        --dry-run|-d)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [[ "$DRY_RUN" == true && -z "$ACTION" ]]; then
    log "$ERROR" "--dry-run must be used with --set or --reset"
    usage
    exit 1
fi

if [[ -z "$ACTION" ]]; then
    usage
    exit 1
fi

case $ACTION in
    set)
        set_preferences
        ;;
    reset)
        reset_preferences
        ;;
esac
