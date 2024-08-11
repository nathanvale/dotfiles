# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

log $INFO "Attempting to remove nerd fonts..."

if ! ./nerd_fonts_manage.sh --remove; then
    log $ERROR "Failed to remove nerd fonts."
    exit 1
fi

log $INFO "Nerd fonts removed successfully."
