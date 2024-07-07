#!/usr/bin/env fish

# FILEPATH: /Users/nathanvale/code/dotfiles/config/fish/functions/custom/yabai_cycle_windows.fish

# This script cycles through the windows in the yabai window manager.
# It swaps the current window with the previous window in the window stack.
# The script uses the 'yabai' command-line tool and 'jq' for JSON parsing.

set win (yabai -m query --windows --window last | jq '.id')

while true
    yabai -m window $win --swap prev &>/dev/null
    if test $status -eq 1
        break
    end
end
