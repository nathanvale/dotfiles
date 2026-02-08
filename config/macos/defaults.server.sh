#!/bin/bash
# defaults.server.sh - Server-specific macOS settings for Mac Mini M4 Pro
#
# Sources:
# - Project note: Mac Mini Home Server Initial Setup
# - Aaron Parker: stealthpuppy.com/mac-mini-home-server/
# - Jeff Geerling: jeffgeerling.com headless CI guide
# - Expert review: macOS Systems Engineer, SRE, DevOps Engineer
#
# Usage:
#   ./defaults.server.sh           # Apply all server settings
#   ./defaults.server.sh --dry-run # Show what would be done
#
# Run via setup.sh or setup.sh prefs on server profile installations.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Track failed commands instead of using set -e (which kills the script silently)
FAILED_COMMANDS=()

# Source colour_log if available, otherwise define minimal logging
if [[ -f "$SCRIPT_DIR/../../bin/colour_log.sh" ]]; then
    source "$SCRIPT_DIR/../../bin/colour_log.sh"
else
    # Minimal fallback logging
    INFO="INFO"
    WARNING="WARNING"
    ERROR="ERROR"
    log() {
        local level=$1
        local message=$2
        echo "[$level] $message"
    }
fi

DRY_RUN=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dry-run|-d)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--dry-run]"
            echo "  --dry-run, -d  Show what would be done without making changes"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Helper to run commands (respects dry-run)
run_cmd() {
    if $DRY_RUN; then
        log "$INFO" "[DRY-RUN] Would execute: $*"
        return 0
    fi

    log "$INFO" "Executing: $*"
    if ! eval "$@"; then
        log "$ERROR" "Command failed: $*"
        FAILED_COMMANDS+=("$*")
        return 1
    fi
}

# Helper for sudo commands with automatic credential recovery
run_sudo() {
    if $DRY_RUN; then
        log "$INFO" "[DRY-RUN] Would execute (sudo): $*"
        return 0
    fi

    # Re-acquire sudo if credentials have expired
    if ! sudo -n true 2>/dev/null; then
        log "$WARNING" "Sudo credentials expired, re-acquiring..."
        if [[ -e /dev/tty ]]; then
            sudo -v < /dev/tty 2>&1 || {
                log "$ERROR" "Failed to re-acquire sudo. Skipping: $*"
                FAILED_COMMANDS+=("$*")
                return 1
            }
        else
            log "$ERROR" "No TTY available to re-acquire sudo. Skipping: $*"
            FAILED_COMMANDS+=("$*")
            return 1
        fi
    fi

    log "$INFO" "Executing (sudo): $*"
    if ! sudo bash -c "$*"; then
        log "$ERROR" "Command failed (sudo): $*"
        FAILED_COMMANDS+=("$*")
        return 1
    fi
}

log "$INFO" "============================================"
log "$INFO" "Server-specific macOS settings"
log "$INFO" "============================================"
if $DRY_RUN; then
    log "$WARNING" "DRY RUN MODE - No changes will be made"
fi

# Validate sudo access upfront before running any commands
if ! $DRY_RUN; then
    if ! sudo -n true 2>/dev/null; then
        log "$WARNING" "Sudo access required for server settings."
        log "$WARNING" "You will be prompted for your password."
        if [[ -e /dev/tty ]]; then
            sudo -v < /dev/tty 2>&1 || {
                log "$ERROR" "Cannot acquire sudo. Run with: sudo ./defaults.server.sh"
                exit 1
            }
        else
            log "$ERROR" "No TTY and no cached sudo credentials."
            log "$ERROR" "Pre-cache sudo first: sudo -v && ./defaults.server.sh"
            exit 1
        fi
    fi
    log "$INFO" "Sudo access: OK"
fi

# ============================================
# HOSTNAME CONFIGURATION
# ============================================
log "$INFO" ""
log "$INFO" "=== Hostname Configuration ==="

# Set hostname (customize as needed)
HOSTNAME="mac-mini-server"
run_sudo "scutil --set ComputerName '$HOSTNAME'"
run_sudo "scutil --set HostName '$HOSTNAME'"
run_sudo "scutil --set LocalHostName '$HOSTNAME'"

# ============================================
# ENERGY SETTINGS (pmset)
# ============================================
log "$INFO" ""
log "$INFO" "=== Energy Settings (pmset) ==="

# Prevent sleep (critical for server)
run_sudo "pmset -a displaysleep 0"      # Display sleep: never
run_sudo "pmset -a sleep 0"             # System sleep: never
run_sudo "pmset -a disksleep 0"         # Disk sleep: never

# Wake and restart options
run_sudo "pmset -a womp 1"              # Wake on network access (magic packet)
run_sudo "pmset -a autorestart 1"       # Auto-restart after power failure
run_sudo "pmset -a powernap 0"          # Disable Power Nap (saves power)

# Additional pmset from expert review
run_sudo "pmset -a hibernatemode 0"     # Disable hibernation
run_sudo "pmset -a standby 0"           # Disable standby (Apple Silicon)
run_sudo "pmset -a autopoweroff 0"      # Disable auto power off
run_sudo "pmset -a proximitywake 0"     # Disable wake when iPhone nearby
run_sudo "pmset -a tcpkeepalive 1"      # Maintain TCP connections during sleep

# ============================================
# SCREEN SAVER & LOCK SCREEN
# ============================================
log "$INFO" ""
log "$INFO" "=== Screen Saver & Lock Screen ==="

# Screen saver: Never (saves CPU, no monitor anyway)
run_cmd "defaults write com.apple.screensaver idleTime 0"

# Login window screen saver: Never (Jeff Geerling recommendation)
run_sudo "defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime 0"

# Lock screen: Require password never (for headless convenience)
# Note: Security tradeoff - acceptable for home server behind firewall
run_cmd "defaults write com.apple.screensaver askForPassword -int 0"
run_cmd "defaults write com.apple.screensaver askForPasswordDelay -int 0"

# ============================================
# BLUETOOTH (Disable for headless)
# ============================================
log "$INFO" ""
log "$INFO" "=== Bluetooth Configuration ==="

# Prevent "Bluetooth Setup Assistant" popup when no keyboard/mouse
run_sudo "defaults write /Library/Preferences/com.apple.Bluetooth BluetoothAutoSeekKeyboard -bool false"
run_sudo "defaults write /Library/Preferences/com.apple.Bluetooth BluetoothAutoSeekPointingDevice -bool false"

# Fully disable Bluetooth (expert recommendation for headless)
run_sudo "defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0"
run_sudo "killall -HUP bluetoothd 2>/dev/null || true"

# ============================================
# SHARING SERVICES (Enable SSH + Screen Sharing)
# ============================================
log "$INFO" ""
log "$INFO" "=== Sharing Services ==="

# Enable Remote Login (SSH)
run_sudo "systemsetup -setremotelogin on 2>/dev/null || true"

# Enable Screen Sharing (VNC) for remote desktop access
run_sudo "launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true"

# ============================================
# FIREWALL (Enable with stealth mode)
# ============================================
log "$INFO" ""
log "$INFO" "=== Firewall Configuration ==="

run_sudo "/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"
run_sudo "/usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on"

# Auto-restart on freeze (kernel panic recovery)
run_sudo "systemsetup -setrestartfreeze on"

# ============================================
# LOGIN WINDOW
# ============================================
log "$INFO" ""
log "$INFO" "=== Login Window ==="

# Show hostname at login window (useful for identifying headless servers)
run_sudo "defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName"

# ============================================
# AUTOMATIC UPDATES (server controls its own reboots)
# ============================================
log "$INFO" ""
log "$INFO" "=== Automatic Updates ==="

run_sudo "defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false"
run_sudo "defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false"
run_sudo "defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool false"

# ============================================
# PERFORMANCE OPTIMIZATIONS
# ============================================
log "$INFO" ""
log "$INFO" "=== Performance Optimizations ==="

# Disable Apple Intelligence / Siri (not needed on server)
run_cmd "defaults write com.apple.assistant.support 'Assistant Enabled' -bool false"

# Disable wallpaper tinting (Aaron Parker recommendation)
run_cmd "defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool false"

# Disable notifications when display sleeping
run_cmd "defaults write com.apple.ncprefs show_previews -int 0"

# Disable startup sound
run_cmd "defaults write NSGlobalDomain com.apple.sound.beep.feedback -bool false"

# Disable App Nap (expert recommendation)
run_cmd "defaults write NSGlobalDomain NSAppSleepDisabled -bool true"

# Disable crash reporter dialogs (expert recommendation)
run_cmd "defaults write com.apple.CrashReporter DialogType none"

# ============================================
# HOT CORNERS (Disable for headless)
# ============================================
log "$INFO" ""
log "$INFO" "=== Hot Corners (Disabled) ==="

# Disable all hot corners (not useful on headless server)
run_cmd "defaults write com.apple.dock wvous-tl-corner -int 0"
run_cmd "defaults write com.apple.dock wvous-tr-corner -int 0"
run_cmd "defaults write com.apple.dock wvous-bl-corner -int 0"
run_cmd "defaults write com.apple.dock wvous-br-corner -int 0"

# ============================================
# SPOTLIGHT (Optional - saves CPU)
# ============================================
# Uncomment to disable Spotlight indexing entirely
# WARNING: Reduces search effectiveness on mounted shares
# log "$INFO" ""
# log "$INFO" "=== Spotlight (Disabled) ==="
# run_sudo "mdutil -a -i off"

# ============================================
# OLLAMA ENVIRONMENT NOTES
# ============================================
log "$INFO" ""
log "$INFO" "=== Ollama Configuration Notes ==="

if ! $DRY_RUN; then
    cat << 'EOF'
For optimal Ollama performance, add to ~/.zshrc or launchd plist:

  export OLLAMA_FLASH_ATTENTION=1      # Enable flash attention
  export OLLAMA_KV_CACHE_TYPE=q8_0     # Quantized KV cache
  export OLLAMA_KEEP_ALIVE=24h         # Keep models in memory
  export OLLAMA_GPU_PERCENT=85         # GPU memory allocation

For launchd service, create ~/Library/LaunchAgents/com.ollama.plist
EOF
fi

# ============================================
# APPLY CHANGES
# ============================================
log "$INFO" ""
log "$INFO" "=== Applying Changes ==="

if ! $DRY_RUN; then
    # Restart affected services
    killall Dock 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true

    if [[ ${#FAILED_COMMANDS[@]} -gt 0 ]]; then
        log "$ERROR" "============================================"
        log "$ERROR" "${#FAILED_COMMANDS[@]} command(s) failed:"
        for cmd in "${FAILED_COMMANDS[@]}"; do
            log "$ERROR" "  - $cmd"
        done
        log "$ERROR" "============================================"
        log "$ERROR" "Re-run with: sudo ./defaults.server.sh"
        exit 1
    fi

    log "$INFO" "============================================"
    log "$INFO" "Server settings applied successfully!"
    log "$INFO" "============================================"
    log "$WARNING" "Some changes require a restart to take full effect."
    log "$INFO" ""
    log "$INFO" "Verification commands:"
    log "$INFO" "  pmset -g                          # Check energy settings"
    log "$INFO" "  systemsetup -getremotelogin       # Check SSH status"
    log "$INFO" "  defaults read com.apple.screensaver idleTime  # Screen saver"
else
    log "$INFO" "============================================"
    log "$INFO" "Dry run complete - no changes made"
    log "$INFO" "============================================"
fi
