#!/bin/bash

# Get the current focused workspace
CURRENT_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE
# echo "Current workspace: $AEROSPACE_FOCUSED_WORKSPACE" >>~/current_workspace.txt
# echo "Previous workspace: $AEROSPACE_PREV_WORKSPACE" >>~/current_workspace.txt

# echo a system alert dialog
# echo "Current workspace: $CURRENT_WORKSPACE" >>~/current_workspace.txt
# Define which application to open for each workspace
case $CURRENT_WORKSPACE in
"1")
    open -a "Ghostty"
    ;;
"2")
    open -a "Visual Studio Code"
    ;;
"3")
    open -a "Arc"
    ;;
"4")
    # Leave this space open for another Arc browser window
     open -a "Arc"
    ;;
"5")
    open -a "Microsoft Teams"
    ;;
"6")
    open -a "Microsoft Outlook"
    ;;
"C")
    open -a "ChatGPT"
    ;;
"M")
    open -a "Messages"
    ;;
"F")    
    open -a "Finder"
    ;;
"O")
    open -a "1Password"
    ;;
"N")
    open -a "Notion"
    ;;
"R")
    open -a "Reminders"
    ;;
"I")
    open -a "Music"
    ;;
*)
    # write to a file in my home directory with the current workspace
    echo "No application assigned for this workspace."
    ;;
esac


# ctrl-cmd-c = 'workspace C'
# ctrl-cmd-s = 'workspace S'
# ctrl-cmd-m = 'workspace M'
# ctrl-cmd-f = 'workspace F'
# ctrl-cmd-o = 'workspace O'
# ctrl-cmd-p = 'workspace P'
# ctrl-cmd-n = 'workspace N'
# ctrl-cmd-r = 'workspace R'
# ctrl-cmd-i = 'workspace I'
