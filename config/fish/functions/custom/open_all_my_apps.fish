# Function: open_all_my_apps
# Description: Opens a list of specified applications.
# Parameters: None
# Returns: None

function open_all_my_apps --description "Open all my apps"
    set apps_to_open iTerm "Visual Studio Code" "Google Chrome" Safari Slack "Microsoft Outlook" "Microsoft Teams" Notes Reminders Calendar
    for app in $apps_to_open
        echo "Opening $app"
        open -a $app
        sleep .5
    end
    sleep 2
    aerospace workspace 1
end
