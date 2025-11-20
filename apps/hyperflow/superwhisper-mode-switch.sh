#!/bin/bash

# SuperWhisper Mode Switcher for Quick Launch (No Tiling Manager)
# Simpler version without AeroSpace workspace management

set -euo pipefail

MODE_KEY="$1"

if [[ -z "$MODE_KEY" ]]; then
    echo "Usage: $0 <mode-key>"
    echo "Available modes: default, casual-text, professional-engineer, email, melanie"
    exit 1
fi

# Configuration
DEBOUNCE_DELAY="${2:-${SUPERWHISPER_DEBOUNCE_DELAY:-0.3}}"
STATE_FILE="/tmp/superwhisper-mode-debounce.state"
LOCK_FILE="/tmp/superwhisper-mode-switch.lock"
DEBUG_MODE="${SUPERWHISPER_DEBUG:-0}"

# Debug logging function
debug_log() {
    # Always log to file for debugging
    echo "[$(date '+%Y-%m-%d %H:%M:%S.%3N')] $*" >> /tmp/superwhisper-debug.log

    # Also log to stderr if debug mode is enabled
    if [[ "$DEBUG_MODE" == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Generate unique timestamp for this invocation (using Python for true microsecond precision on macOS)
MY_TIMESTAMP=$(python3 -c "import time; print(f'{time.time():.6f}')")

debug_log "START: Mode switch to '$MODE_KEY' (timestamp: $MY_TIMESTAMP, PID: $$)"

# Write state atomically using temp file + mv
TMP_FILE=$(mktemp)
echo "$MY_TIMESTAMP|$MODE_KEY" > "$TMP_FILE"
mv "$TMP_FILE" "$STATE_FILE"

debug_log "State written: $MY_TIMESTAMP|$MODE_KEY"

# Debounce: wait for rapid switching to stop
debug_log "Sleeping for ${DEBOUNCE_DELAY}s (debounce)"
sleep "$DEBOUNCE_DELAY"

# Check if I'm still the latest request
CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "")
CURRENT_TIMESTAMP=$(echo "$CURRENT_STATE" | cut -d'|' -f1)

if [[ "$CURRENT_TIMESTAMP" != "$MY_TIMESTAMP" ]]; then
    # A newer request came in, exit silently
    debug_log "CANCELLED: Newer request exists (current: $CURRENT_TIMESTAMP, mine: $MY_TIMESTAMP)"
    exit 0
fi

debug_log "I'm the latest request after debounce, attempting to apply mode '$MODE_KEY'"

# Try to acquire lock WITHOUT waiting (non-blocking)
# If lock is held, it means another mode switch is in progress - we should exit
debug_log "Attempting to acquire lock (non-blocking)..."
if mkdir "$LOCK_FILE" 2>/dev/null; then
    debug_log "Lock acquired successfully"
else
    # Lock is held by another process that's currently switching modes
    # Exit immediately to avoid lag
    debug_log "CANCELLED: Lock held by active mode switch, exiting to avoid lag"
    exit 0
fi

# Ensure we release the lock on exit
trap "rmdir '$LOCK_FILE' 2>/dev/null || true; debug_log 'Lock released (trap)'" EXIT

# Double-check we're still the latest request after acquiring lock
CURRENT_STATE_RECHECK=$(cat "$STATE_FILE" 2>/dev/null || echo "")
CURRENT_TIMESTAMP_RECHECK=$(echo "$CURRENT_STATE_RECHECK" | cut -d'|' -f1)

if [[ "$CURRENT_TIMESTAMP_RECHECK" != "$MY_TIMESTAMP" ]]; then
    debug_log "CANCELLED: State changed while acquiring lock (current: $CURRENT_TIMESTAMP_RECHECK, mine: $MY_TIMESTAMP)"
    exit 0
fi

debug_log "APPLYING: Lock acquired and still latest request, applying mode '$MODE_KEY'"

# Capture the frontmost app and window BEFORE mode switch
debug_log "Step 1: Capturing frontmost app..."
FOCUSED_APP=$(osascript -e 'tell application "System Events" to name of first process whose frontmost is true' 2>/dev/null || echo "")
debug_log "Frontmost app captured: '$FOCUSED_APP'"

debug_log "Step 2: Capturing window title for '$FOCUSED_APP'..."
WINDOW_TITLE=$(osascript -e "tell application \"System Events\" to tell process \"$FOCUSED_APP\" to get name of front window" 2>/dev/null || echo "")
debug_log "Window title captured: '$WINDOW_TITLE'"

# Also capture the window list to understand the state
debug_log "Step 3: Capturing window list for debugging..."
WINDOW_LIST=$(osascript -e "tell application \"System Events\" to tell process \"$FOCUSED_APP\" to get name of every window" 2>/dev/null || echo "")
debug_log "Available windows in '$FOCUSED_APP': $WINDOW_LIST"

debug_log "Before mode switch - App: '$FOCUSED_APP', Window: '$WINDOW_TITLE'"

# Map process names to application names for AppleScript
# Some apps have different process names vs application names
map_process_to_app() {
    local process_name="$1"
    case "$process_name" in
        "Electron")
            echo "Visual Studio Code"
            ;;
        *)
            echo "$process_name"
            ;;
    esac
}

# Get the application name for AppleScript commands
APP_NAME_FOR_APPLESCRIPT=$(map_process_to_app "$FOCUSED_APP")
debug_log "Mapped process '$FOCUSED_APP' to app name '$APP_NAME_FOR_APPLESCRIPT' for AppleScript"

# Apply the mode change
debug_log "Step 4: Opening SuperWhisper deep link for mode '$MODE_KEY'..."
open "superwhisper://mode?key=$MODE_KEY" 2>/dev/null || true
debug_log "Deep link opened"

# Wait for SuperWhisper to process the mode change
debug_log "Step 5: Sleeping 0.3s for SuperWhisper to process..."
sleep 0.3
debug_log "Sleep complete"

debug_log "Step 6: Checking frontmost app after mode switch..."
FOCUSED_APP_AFTER=$(osascript -e 'tell application "System Events" to name of first process whose frontmost is true' 2>/dev/null || echo "")
debug_log "Frontmost app AFTER mode switch: '$FOCUSED_APP_AFTER' (was: '$FOCUSED_APP')"

debug_log "Mode change complete, attempting to restore focus to '$FOCUSED_APP'"

# Restore focus to the app that was focused before mode switch
if [[ -n "$FOCUSED_APP" ]]; then
    debug_log "Step 7: Re-activating app '$APP_NAME_FOR_APPLESCRIPT' (process: '$FOCUSED_APP')..."

    # Re-activate the app using the mapped application name
    ACTIVATE_RESULT=$(osascript -e "tell application \"$APP_NAME_FOR_APPLESCRIPT\" to activate" 2>&1)
    ACTIVATE_EXIT=$?
    debug_log "Activation result: exit code $ACTIVATE_EXIT, output: '$ACTIVATE_RESULT'"

    # Small delay after activation
    sleep 0.1
    debug_log "Post-activation sleep complete"

    # Check what's frontmost now
    FOCUSED_AFTER_ACTIVATE=$(osascript -e 'tell application "System Events" to name of first process whose frontmost is true' 2>/dev/null || echo "")
    debug_log "Frontmost app after activation: '$FOCUSED_AFTER_ACTIVATE'"

    # If we captured the window title, try to bring that specific window to front
    if [[ -n "$WINDOW_TITLE" ]] && [[ "$WINDOW_TITLE" != "missing value" ]]; then
        debug_log "Step 8: Attempting to bring window '$WINDOW_TITLE' to front..."

        # Escape single quotes in window title for AppleScript
        ESCAPED_TITLE=$(echo "$WINDOW_TITLE" | sed "s/'/\\\\'/g")
        debug_log "Escaped window title: '$ESCAPED_TITLE'"

        # Try Method 1: Using System Events to perform window action (more reliable)
        WINDOW_RESULT=$(osascript -e "
            tell application \"System Events\"
                tell process \"$FOCUSED_APP\"
                    try
                        set frontmost to true
                        perform action \"AXRaise\" of window \"$ESCAPED_TITLE\"
                        return \"success (System Events)\"
                    on error errMsg
                        return \"error (System Events): \" & errMsg
                    end try
                end tell
            end tell
        " 2>&1)
        debug_log "Window focus result (System Events): '$WINDOW_RESULT'"

        # If System Events didn't work, try the app-specific method
        if [[ "$WINDOW_RESULT" == error* ]]; then
            debug_log "System Events method failed, trying app-specific method..."
            WINDOW_RESULT2=$(osascript -e "
                tell application \"$APP_NAME_FOR_APPLESCRIPT\"
                    try
                        set index of window \"$ESCAPED_TITLE\" to 1
                        return \"success (app-specific)\"
                    on error errMsg
                        return \"error (app-specific): \" & errMsg
                    end try
                end tell
            " 2>&1)
            debug_log "Window focus result (app-specific): '$WINDOW_RESULT2'"
        fi

        debug_log "Restored focus to window '$WINDOW_TITLE' in '$FOCUSED_APP'"
    else
        debug_log "No specific window title to restore (title was: '$WINDOW_TITLE')"
        debug_log "Restored focus to '$FOCUSED_APP' (no specific window)"
    fi

    # Small delay to let activation complete
    debug_log "Step 9: Final sleep 0.05s to let activation complete..."
    sleep 0.05
    debug_log "Final sleep complete"

    # Final check
    FOCUSED_FINAL=$(osascript -e 'tell application "System Events" to name of first process whose frontmost is true' 2>/dev/null || echo "")
    debug_log "FINAL frontmost app: '$FOCUSED_FINAL' (expected: '$FOCUSED_APP')"

    if [[ "$FOCUSED_FINAL" != "$FOCUSED_APP" ]]; then
        debug_log "WARNING: Final frontmost app '$FOCUSED_FINAL' does not match expected '$FOCUSED_APP'!"
    else
        debug_log "SUCCESS: Focus correctly restored to '$FOCUSED_APP'"
    fi
else
    debug_log "No focused app to restore (FOCUSED_APP was empty)"
fi

debug_log "COMPLETE: Mode switch to '$MODE_KEY' finished successfully"

# Release lock
rmdir "$LOCK_FILE" 2>/dev/null || true
debug_log "Lock released (normal exit)"

exit 0
