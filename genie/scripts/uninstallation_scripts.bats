#!/usr/bin/env bats

# Define the URLs of the scripts to download in the required order
uninstallation_urls=(
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/check_shell.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/brew_uninstall.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/macos_preferences_uninstall.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/dotfiles_uninstall.sh"
    "https://raw.githubusercontent.com/nathanvale/dotfiles/master/genie/scripts/symlinks_uninstall.sh"
)

# Convert to an array of basenames
uninstallation_scripts=()
for url in "${uninstallation_urls[@]}"; do
    uninstallation_scripts+=("$(basename "$url")")
done

# Test to check if the conversion to basenames is correct
@test "conversion to basenames" {
    expected_scripts=("check_shell.sh" "brew_uninstall.sh" "macos_preferences_uninstall.sh" "dotfiles_uninstall.sh")
    run echo "${uninstallation_scripts[@]}"
    for i in "${!expected_scripts[@]}"; do
        [ "${expected_scripts[$i]}" = "${uninstallation_scripts[$i]}" ]
    done
}

# Test to check if all URLs are accessible
@test "check URLs accessibility" {
    for url in "${uninstallation_urls[@]}"; do
        run curl -Is "$url" | head -n 1
        [ "$status" -eq 0 ]
        [[ "$output" =~ 200 ]]
    done
}

# Test to download the scripts
@test "download scripts" {
    for url in "${uninstallation_urls[@]}"; do
        run curl -O "$url"
        [ "$status" -eq 0 ]
    done
}

# Test to check if all scripts were downloaded successfully
@test "check downloaded scripts" {
    for script in "${uninstallation_scripts[@]}"; do
        [ -f "$script" ]
    done
}

# Cleanup downloaded scripts
teardown() {
    for script in "${uninstallation_scripts[@]}"; do
        rm -f "$script"
    done
}
