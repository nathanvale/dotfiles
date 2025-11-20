# Define the URLs of the scripts to download in the required order
set -e  # Exit on error

installation_urls=(
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/check_shell.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/brew_install.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/brew_remote_bundle.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/dotfiles_install.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/symlinks_install.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/nerd_fonts_install.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/iterm_preferences_install.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/macos_preferences_install.sh"
)

# Convert to an array of basenames
installation_scripts=()
for url in "${installation_urls[@]}"; do
    installation_scripts+=("$(basename "$url")")
done
