#!/bin/bash
# Quick tmuxinator session launcher

# Get list of tmuxinator projects (skip the header line and filter out _base)
projects=$(tmuxinator list -n | grep -v "tmuxinator projects:" | grep -v "_base" | xargs)

# Get existing sessions (filter out _base)
existing_sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -v "_base")

# Combine projects and mark existing sessions with 1-based numbering
all_options=""
counter=1
for project in $projects; do
    if echo "$existing_sessions" | grep -q "^$project$"; then
        all_options="$all_options$counter. $project [running]\n"
    else
        all_options="$all_options$counter. $project\n"
    fi
    counter=$((counter + 1))
done

# Add existing sessions that aren't projects
for session in $existing_sessions; do
    if ! echo "$projects" | grep -q "$session"; then
        all_options="$all_options$counter. $session [running]\n"
        counter=$((counter + 1))
    fi
done

# Use fzf to select a project (or type a new session name)
selected=$(echo -e "$all_options" | fzf --height=40% --border --prompt="Select project or type new session name: " --print-query | tail -1)

# Remove number prefix and [running] suffix if present
selected=$(echo "$selected" | sed 's/^[0-9]*\. *//' | sed 's/ \[running\]$//')

if [ -n "$selected" ]; then
    # Check if session already exists
    if tmux has-session -t "$selected" 2>/dev/null; then
        # Session exists - attach or switch to it
        if [ -n "$TMUX" ]; then
            tmux switch-client -t "$selected"
        else
            exec tmux attach-session -t "$selected"
        fi
    elif echo "$projects" | grep -q "$selected"; then
        # It's a tmuxinator project - start it
        if [ -n "$TMUX" ]; then
            # We're in tmux, start in background and switch
            tmuxinator start "$selected"
            tmux switch-client -t "$selected"
        else
            # Not in tmux, start normally
            exec tmuxinator start "$selected"
        fi
    else
        # It's a new session name - offer to create tmuxinator config
        
        # Check if this looks like a project directory path
        if [ -d "$HOME/code/$selected" ]; then
            project_path="$HOME/code/$selected"
        elif [ -d "./$selected" ]; then
            project_path="./$selected"
        else
            project_path=""
        fi
        
        # If we found a potential project directory, offer to generate tmuxinator config
        if [ -n "$project_path" ] && [ -d "$project_path" ]; then
            echo "📁 Found project directory: $project_path"
            echo "💡 Tip: Use 'tmuxnew' to generate configs or 'tcd <project>' to jump to projects"
            echo
            read -p "🚀 Generate tmuxinator config for this project? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Check if aliases are loaded
                if ! command -v tmuxnew &> /dev/null; then
                    echo "ℹ️  First time setup: Run 'source ~/.zshrc' to load the new commands"
                    echo "   Then you can use: tmuxnew, tcd, tmuxgen"
                    echo
                fi
                # Generate the config using our new script
                "$HOME/code/dotfiles/bin/tmux/new-project.sh" "$selected"
            else
                # Just create a basic tmux session
                if [ -n "$TMUX" ]; then
                    tmux new-session -d -s "$selected"
                    tmux switch-client -t "$selected"
                else
                    exec tmux new-session -s "$selected"
                fi
            fi
        else
            # Not a project directory, just create a basic tmux session
            if [ -n "$TMUX" ]; then
                tmux new-session -d -s "$selected"
                tmux switch-client -t "$selected"
            else
                exec tmux new-session -s "$selected"
            fi
        fi
    fi
fi