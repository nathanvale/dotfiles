#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open All My Apps
# @raycast.mode compact

open_all_my_apps() {
    # Define an array of applications to open on my work Mac
    apps_to_open=("Ghostty" "Visual Studio Code" "Arc" "Microsoft Teams" "Microsoft Outlook", "ChatGPT"  "Notion" "Raycast" "Aerospace" "AlDente")

    # Loop through each application in the list and open it
    for app in "${apps_to_open[@]}"; do
        echo "Opening $app"
        open -a "$app"
    done

    aerospace workspace 1
}

# Call the function to execute the script
open_all_my_apps
