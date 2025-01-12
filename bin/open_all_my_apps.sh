#!/bin/bash

# Function: open_all_my_apps
# Description: Opens a list of specified applications.
# Parameters: None
# Returns: None

open_all_my_apps() {
    # Define an array of applications to open on my work Mac
    apps_to_open=("iTerm" "Visual Studio Code" "Arc" "Microsoft Teams" "Messages")

    # Loop through each application in the list and open it
    for app in "${apps_to_open[@]}"; do
        echo "Opening $app"
        open -a "$app"
    done

    aerospace workspace 1
}

# Call the function to execute the script
open_all_my_apps
