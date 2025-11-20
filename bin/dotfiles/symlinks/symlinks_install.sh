# Ensure the script is being run from the correct directory
set -e  # Exit on error

cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

log "$INFO" "Attempting to create dotfiles symlinks..."


if ! ./symlinks_manage.sh --link; then
    log "$ERROR" "Failed to create dotfiles symlinks."
    exit 1
fi

log "$INFO" "Dotfiles symlinks created successfully."
