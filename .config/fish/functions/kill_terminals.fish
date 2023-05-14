function kill_terminals
    # Get the process IDs (PIDs) of all Terminal windows
    set terminal_pids (ps -ax | grep -i "Terminal.app" | grep -v grep | awk '{print $1}')

    # Check if any Terminal windows are open
    if test -n "$terminal_pids"
        echo "Closing all Terminal windows..."

        # Kill each Terminal window process
        for pid in $terminal_pids
            kill $pid
            osascript -e "tell application \"Terminal\" to close (every window whose id is $pid)"
        end
        echo "All Terminal windows closed."
        sleep 2
        osascript -e "tell application \"Terminal\" to quit"
        echo "Terminal app force quit"
    else
        echo "No open Terminal windows found."
    end


end