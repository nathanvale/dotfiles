function yabai_reset_windows --description "Query all windows and move them to the correct space"
    # Check the number of displays
    set display_count (yabai -m query --displays | jq 'length')

    if test $display_count -eq 2
        set target_spaces 9 # 8 spaces + 1 for the second display
    else
        set target_spaces 8 # 8 spaces for a single display
    end

    # Ensure there are the correct number of spaces
    set current_spaces (yabai -m query --spaces | jq 'length')

    if test $current_spaces -lt $target_spaces
        set difference (math "$target_spaces - $current_spaces")
        for i in (seq $difference)
            yabai -m space --create
        end
    else if test $current_spaces -gt $target_spaces
        set difference (math "$current_spaces - $target_spaces")
        for i in (seq $difference)
            set space_id (yabai -m query --spaces | jq '.[-1].index')
            yabai -m space --destroy $space_id
        end
    end

    # Query all windows and move them to the correct space
    set windows (yabai -m query --windows | jq -r '.[] | "\(.id) \(.app) \(.title)"')

    for window in $windows
        set -l window_id (echo $window | awk '{print $1}')
        set -l app (echo $window | awk '{print $2}')
        set -l title (echo $window | awk '{$1=$2=""; print $0}' | xargs)

        switch $app
            case iTerm2
                echo "Moving $app to space 1"
                yabai -m window $window_id --space 1
                yabai -m window --focus $window_id
            case Code
                echo "Moving $app to space 2"
                yabai -m window $window_id --space 2
                yabai -m window --focus $window_id
            case Google
                echo "Moving $app to space 3"
                yabai -m window $window_id --space 3
                yabai -m window --focus $window_id
            case Safari
                echo "Moving $app to space 4"
                yabai -m window $window_id --space 4
                yabai -m window --focus $window_id
            case Slack
                echo "Moving $app to space 5"
                yabai -m window $window_id --space 5
                yabai -m window --focus $window_id
            case Microsoft
                echo "Moving $app to space 6"
                yabai -m window $window_id --space 6
                yabai -m window --focus $window_id
            case "*"
                echo "Moving $app to space 8"
                yabai -m window $window_id --space 8
                yabai -m window --focus $window_id
        end
        sleep 1
    end
end
