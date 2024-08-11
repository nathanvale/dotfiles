# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

log $INFO "Attempting to add nerd fonts..."

if ! ./nerd_fonts_manage.sh --add; then
    log $ERROR "Failed to add nerd fonts."
    exit 1
fi

log $INFO "nerd fonts added successfully."
