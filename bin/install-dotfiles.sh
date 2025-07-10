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

install_dotfiles() {
    local error_message="An error occurred installing dotfiles."
    local scripts=(
        "check_shell.sh"
        "brew_install.sh"
        "brew_remote_bundle.sh"
        "dotfiles_install.sh"
        "symlinks_install.sh"
        "nerd_fonts_install.sh"
        "iterm_preferences_install.sh"
        "macos_preferences_install.sh"
    )

    log $INFO "Installing nathanvale/dotfiles..."

    execute_scripts "$error_message" "${scripts[@]}"

    log $INFO "Installation of dotfiles completed successfully."

    sleep 2

    open '/Applications/Karabiner-Elements.app/' 2>/dev/null || true
    open '/Applications/Aerospace.app/' 2>/dev/null || true
}

install_dotfiles