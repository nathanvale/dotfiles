#!/usr/bin/env fish

function kill_vpn
    while true
        # Check if GlobalProtect app is running
        if pgrep -x "GlobalProtect" >/dev/null
            # Close GlobalProtect app
            osascript -e 'quit app "GlobalProtect"'
            echo "GlobalProtect app closed."
        end

        sleep 1 # Adjust the sleep duration as needed
    end
end