#!/bin/bash
# tmux-cycle-attached.sh - Cycle only through sessions with attached clients

# Get current session
current_session=$(tmux display-message -p '#S')

# Get all sessions with attached clients, ordered by name
attached_sessions=$(tmux list-sessions -F "#{session_name}:#{session_attached}" | grep ":1$" | cut -d: -f1 | sort)

# Convert to array
sessions_array=($attached_sessions)
session_count=${#sessions_array[@]}

# If only one or no attached sessions, do nothing
if [ $session_count -le 1 ]; then
    exit 0
fi

# Find current session index
current_index=-1
for i in "${!sessions_array[@]}"; do
    if [ "${sessions_array[$i]}" = "$current_session" ]; then
        current_index=$i
        break
    fi
done

# If current session not found in attached list, switch to first attached
if [ $current_index -eq -1 ]; then
    next_session="${sessions_array[0]}"
else
    # Calculate next index (wrap around)
    next_index=$(( (current_index + 1) % session_count ))
    next_session="${sessions_array[$next_index]}"
fi

# Switch to next attached session
tmux switch-client -t "$next_session"