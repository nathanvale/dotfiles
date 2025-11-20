# Define the URLs of the scripts to download in the required order
set -e  # Exit on error

uninstallation_urls=(
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/check_shell.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/brew_uninstall.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/nerd_fonts_uninstall.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/iterm_preferences_uninstall.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/macos_preferences_uninstall.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/symlinks_uninstall.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/dotfiles_uninstall.sh"
)

# Convert to an array of basenames
uninstallation_scripts=()
for url in "${uninstallation_urls[@]}"; do
    uninstallation_scripts+=("$(basename "$url")")
done
