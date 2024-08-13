# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

log $INFO "Attempting to set remove iTerm2 preferences..."

./iterm_preferences_manage.sh --delete
