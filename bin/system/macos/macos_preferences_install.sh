# Ensure the script is being run from the correct directory
set -e  # Exit on error

cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

"log $INFO ""Attempting to set macos preferences..."


if ! ./macos_preferences_manage.sh --set; then
    "log $ERROR ""Failed to set macos preferences."
    exit 1
fi

"log $INFO ""macos preferences set successfully."
