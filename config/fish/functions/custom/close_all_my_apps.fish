# FUNCTION: close_all_my_apps
# DESCRIPTION: Close all my apps except specified ones
#
# This function closes all open applications on the system, except for the ones specified in the `keepapps` list.
# It retrieves the list of currently running applications using AppleScript, and then iterates over each application.
# If the application is not in the `keepapps` list, it attempts to gracefully quit the application using AppleScript.
# If the application does not quit within .5 seconds, it forcefully kills the application using the `kill` command.
#
# Parameters:
#   None
#
# Example usage:
#   close_all_my_apps
#
# Dependencies:
#   - AppleScript
#   - pgrep
#   - kill
#
# Returns:+
#   None

function close_all_my_apps --description "Close all my apps except specified ones"
    # List of apps to keep open
    set -l keepapps iTerm2
    # Get the list of application names
    set -l quitapps (osascript -e 'tell application "System Events" to get name of (every application process whose background only is false and name is not "Finder")')
    # Convert the list into an array
    for app in (echo $quitapps | sed 's/, /\n/g')
        set app (string trim -c " " $app) # Trim leading and trailing whitespace
        if not contains $app $keepapps
            echo "Closing $app"
            # Get the process ID of the application
            set pid (pgrep -x "$app")
            if test "$pid" != ""
                # Quit the application using osascript
                osascript -e "tell application \"$app\" to quit"
                # Wait a bit to ensure the app quits gracefully
                sleep .5
                # Force kill the app if it's still running
                if test (pgrep -x "$app")
                    echo "Force killing $app"
                    kill -9 $pid
                end
            end
        end
    end
    aerospace workspace 1
end
