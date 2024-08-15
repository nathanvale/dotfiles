#!/bin/bash

# Function: open_all_my_apps
# Description: Opens a list of specified applications.
# Parameters: None
# Returns: None

open_all_my_apps() {
    # Define an array of applications to open
    apps_to_open=("iTerm" "Visual Studio Code" "Google Chrome" "Safari" "Slack" "Microsoft Outlook" "Notes" "Reminders" "Calendar")

    # Loop through each application in the list and open it
    for app in "${apps_to_open[@]}"; do
        echo "Opening $app"
        open -a "$app"
        sleep 0.5
    done

    sleep 2

    aerospace workspace 1
}

# Call the function to execute the script
open_all_my_apps
