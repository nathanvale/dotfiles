# Ensure the script is being run from the correct directory
cd "$(dirname "$0")"

# Source the colour_log.sh script
source "./colour_log.sh"

log $INFO "Attempting to configure yabai scripting addition..."


if ! ./yabai_sa_manage.sh --configure; then
    log $ERROR "Failed to create dotfiles symlinks."
    exit 1
fi

log $INFO "yabai scripting addition configured successfully."
