# Ensure the script is being run from the correct directory
set -e  # Exit on error

cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

log $INFO "Attempting to remove nerd fonts..."

./nerd_fonts_manage.sh --remove
