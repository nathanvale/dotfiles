# Function: open_chatgpt
# Description: Opens the ChatGPT website in Safari and moves the Safari window to space 4.
#              It also focuses on space 4.
function open_chatgpt
    osascript ~/Scripts/check_and_open_safari.applescript "https://chatgpt.com"
    if yabai -m query --windows --space | grep -q '"app":"Safari"'
        then
        # Move the Safari window to space 4
        yabai -m window --space 4
    end

    yabai -m space --focus 4
end
