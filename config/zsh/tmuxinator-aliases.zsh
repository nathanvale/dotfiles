#!/usr/bin/env zsh
# Tmuxinator shortcuts and aliases

# Quick tmuxinator project generation
alias tmuxnew='~/code/dotfiles/bin/tmuxinator-new-project.sh'
alias tnew='~/code/dotfiles/bin/tmuxinator-new-project.sh'

# Quick tmuxinator commands
alias mux='tmuxinator'
alias tl='tmuxinator list'
alias ts='tmuxinator start'
alias te='tmuxinator edit'
alias tn='tmuxinator new'
alias td='tmuxinator delete'

# Function to quickly generate and start a new project
tmuxgen() {
    if [ $# -eq 0 ]; then
        # Use current directory
        ~/code/dotfiles/bin/tmuxinator-new-project.sh
    else
        # Use provided project name
        ~/code/dotfiles/bin/tmuxinator-new-project.sh "$1"
    fi
}

# Function to jump to a project directory and start tmuxinator
tcd() {
    if [ $# -eq 0 ]; then
        echo "Usage: tcd <project-name>"
        return 1
    fi
    
    local project_dir="$HOME/code/$1"
    
    if [ ! -d "$project_dir" ]; then
        echo "Project directory not found: $project_dir"
        return 1
    fi
    
    cd "$project_dir"
    
    # Check if tmuxinator config exists
    if [ -f "$HOME/.config/tmuxinator/$1.yml" ]; then
        tmuxinator start "$1"
    else
        echo "No tmuxinator config found for $1"
        read -q "?Generate one now? (y/n): "
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ~/code/dotfiles/bin/tmuxinator-new-project.sh "$1"
        fi
    fi
}