#!/bin/bash

# tmux-open-vscode.sh
# Opens VS Code for the current pane's working directory

# Get the current pane's working directory
current_dir=$(tmux display-message -p '#{pane_current_path}')

# Check if the code command is available
if ! command -v code &> /dev/null; then
    tmux display-message "VS Code CLI not found. Install with: brew install --cask visual-studio-code"
    exit 1
fi

# Open VS Code for the current directory
code "$current_dir"

# Display confirmation message in tmux
tmux display-message "Opening VS Code for: $current_dir"