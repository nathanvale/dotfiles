# Ensure the script is being run from the correct directory
set -e  # Exit on error

cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

log $INFO "Attempting to reset macos preferences..."


if ! ./macos_preferences_manage.sh --reset; then
    log $ERROR "Failed to reset macos preferences."
    exit 1
fi

log $INFO "macos preferences reset successfully."
