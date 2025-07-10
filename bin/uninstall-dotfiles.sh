#!/bin/bash

set -e

cd "$(dirname "$0")"

source "./colour_log.sh"

execute_scripts() {
    local error_message="$1"
    shift 1
    local scripts=("$@")

    log $INFO "Executing scripts: ${scripts[@]}"

    for script in "${scripts[@]}"; do
        if [[ -x "./$script" ]]; then
            if ! "./$script"; then
                log $ERROR "$error_message"
                exit 1
            fi
        else
            log $ERROR "Script ./$script is not executable."
            log $ERROR "$error_message"
            exit 1
        fi
    done
}

uninstall_dotfiles() {
    local error_message="An error occurred uninstalling dotfiles."
    local scripts=(
        "dotfiles_uninstall.sh"
        "symlinks_uninstall.sh"
        "nerd_fonts_uninstall.sh"
        "iterm_preferences_uninstall.sh"
        "macos_preferences_uninstall.sh"
        "brew_uninstall.sh"
    )

    log $INFO "Uninstalling nathanvale/dotfiles..."

    execute_scripts "$error_message" "${scripts[@]}"

    log $INFO "Uninstallation of dotfiles completed successfully."
}

uninstall_dotfiles