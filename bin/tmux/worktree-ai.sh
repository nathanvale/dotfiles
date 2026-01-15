#!/bin/bash
# bin/tmux/worktree-ai.sh
# Create or attach to a git worktree and spawn 4 Claude AI panes
#
# Usage: worktree-ai.sh [branch-name]
#   - With no args: shows fzf picker for existing worktrees/branches
#   - With branch name: creates new worktree or attaches to existing

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

WORKTREE_DIR=".worktrees"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

info() { printf "${BLUE}%s${NC}\n" "$1"; }
success() { printf "${GREEN}%s${NC}\n" "$1"; }
warning() { printf "${YELLOW}%s${NC}\n" "$1"; }
error() { printf "${RED}%s${NC}\n" "$1" >&2; exit 1; }

# Check if we're in a git repo
check_git_repo() {
    if ! git rev-parse --git-dir &>/dev/null; then
        error "Not in a git repository"
    fi
}

# Get the root of the main worktree (not a linked worktree)
get_repo_root() {
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)

    if [[ "$git_common_dir" == ".git" ]]; then
        # We're in the main worktree
        pwd
    else
        # We're in a linked worktree, get the main repo path
        dirname "$git_common_dir"
    fi
}

# List existing worktrees (excluding main)
list_worktrees() {
    git worktree list --porcelain | grep "^worktree " | cut -d' ' -f2- | while read -r wt; do
        # Skip if it's the main worktree
        if [[ "$wt" != "$(get_repo_root)" ]]; then
            local branch
            branch=$(git -C "$wt" branch --show-current 2>/dev/null || echo "detached")
            echo "worktree:$branch:$wt"
        fi
    done
}

# List remote branches not yet checked out
list_remote_branches() {
    git branch -r --no-merged 2>/dev/null | grep -v HEAD | sed 's/origin\///' | while read -r branch; do
        # Skip if already a local branch
        if ! git show-ref --verify --quiet "refs/heads/$branch"; then
            echo "remote:$branch"
        fi
    done
}

# List local branches without worktrees
list_local_branches() {
    local worktree_branches
    worktree_branches=$(git worktree list --porcelain | grep "^branch " | sed 's/branch refs\/heads\///')

    git branch --format='%(refname:short)' | while read -r branch; do
        if ! echo "$worktree_branches" | grep -qx "$branch"; then
            echo "branch:$branch"
        fi
    done
}

# Show fzf picker for branch/worktree selection
pick_branch() {
    local choices=""

    # Header option to create new branch
    choices="${CYAN}[+] Create new branch${NC}\n"

    # Existing worktrees (can attach)
    local worktrees
    worktrees=$(list_worktrees)
    if [[ -n "$worktrees" ]]; then
        choices+="${GREEN}── Existing Worktrees ──${NC}\n"
        choices+="$worktrees\n"
    fi

    # Local branches (can create worktree)
    local local_branches
    local_branches=$(list_local_branches)
    if [[ -n "$local_branches" ]]; then
        choices+="${YELLOW}── Local Branches ──${NC}\n"
        choices+="$local_branches\n"
    fi

    # Remote branches (can checkout + create worktree)
    local remote_branches
    remote_branches=$(list_remote_branches)
    if [[ -n "$remote_branches" ]]; then
        choices+="${BLUE}── Remote Branches ──${NC}\n"
        choices+="$remote_branches\n"
    fi

    # Use fzf to pick
    local selection
    selection=$(echo -e "$choices" | fzf --ansi --height=50% --reverse \
        --header="Select worktree/branch (or create new)" \
        --preview='
            line={}
            if [[ "$line" == worktree:* ]]; then
                path=$(echo "$line" | cut -d: -f3)
                echo "📁 Worktree: $path"
                echo ""
                git -C "$path" log --oneline -5 2>/dev/null
            elif [[ "$line" == branch:* ]] || [[ "$line" == remote:* ]]; then
                branch=$(echo "$line" | cut -d: -f2)
                echo "🌿 Branch: $branch"
                echo ""
                git log --oneline -5 "$branch" 2>/dev/null || git log --oneline -5 "origin/$branch" 2>/dev/null
            fi
        ' \
        --preview-window=right:50%:wrap \
        2>/dev/null) || exit 0

    echo "$selection"
}

# Prompt for new branch name
prompt_new_branch() {
    echo ""
    printf "${CYAN}Enter new branch name: ${NC}"
    read -r branch_name

    if [[ -z "$branch_name" ]]; then
        error "Branch name cannot be empty"
    fi

    # Sanitize branch name
    branch_name=$(echo "$branch_name" | sed 's/[^a-zA-Z0-9._-]/-/g')
    echo "$branch_name"
}

# Create or get worktree path for a branch
ensure_worktree() {
    local branch="$1"
    local repo_root
    repo_root=$(get_repo_root)
    local worktree_path="$repo_root/$WORKTREE_DIR/$branch"

    # Check if worktree already exists
    if git worktree list --porcelain | grep -q "^worktree $worktree_path$"; then
        echo "$worktree_path"
        return 0
    fi

    # Create worktrees directory if needed
    mkdir -p "$repo_root/$WORKTREE_DIR"

    # Check if branch exists locally
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        info "Creating worktree for existing branch: $branch"
        git worktree add "$worktree_path" "$branch"
    # Check if branch exists on remote
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        info "Creating worktree for remote branch: $branch"
        git worktree add "$worktree_path" -b "$branch" "origin/$branch"
    else
        # New branch from current HEAD
        info "Creating worktree with new branch: $branch"
        git worktree add -b "$branch" "$worktree_path"
    fi

    echo "$worktree_path"
}

# Create tmux window with 4 Claude panes
create_ai_window() {
    local worktree_path="$1"
    local branch="$2"
    local session_name

    session_name=$(tmux display-message -p '#S')

    # Window name is the branch (sanitized for tmux)
    local window_name
    window_name=$(echo "$branch" | tr '/' '-' | cut -c1-20)

    # Create new window
    tmux new-window -t "$session_name" -n "$window_name" -c "$worktree_path"

    # Split into 4 panes (tiled layout)
    tmux split-window -t "$session_name:$window_name" -h -c "$worktree_path"
    tmux split-window -t "$session_name:$window_name.1" -v -c "$worktree_path"
    tmux split-window -t "$session_name:$window_name.2" -v -c "$worktree_path"

    # Apply tiled layout
    tmux select-layout -t "$session_name:$window_name" tiled

    # Start Claude in each pane with staggered delays
    tmux send-keys -t "$session_name:$window_name.1" "ccdev" C-m
    tmux send-keys -t "$session_name:$window_name.2" "sleep 2 && ccdev" C-m
    tmux send-keys -t "$session_name:$window_name.3" "sleep 4 && ccdev" C-m
    tmux send-keys -t "$session_name:$window_name.4" "sleep 6 && ccdev" C-m

    # Select first pane
    tmux select-pane -t "$session_name:$window_name.1"

    success "Created AI window '$window_name' with 4 Claude panes"
    echo "Worktree: $worktree_path"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Check prerequisites
    if [[ -z "$TMUX" ]]; then
        error "Not in a tmux session"
    fi

    check_git_repo

    local branch=""
    local worktree_path=""

    if [[ -n "$1" ]]; then
        # Branch name provided as argument
        branch="$1"
    else
        # Show picker
        local selection
        selection=$(pick_branch)

        if [[ "$selection" == *"Create new branch"* ]]; then
            branch=$(prompt_new_branch)
        elif [[ "$selection" == worktree:* ]]; then
            # Existing worktree - extract path and branch
            branch=$(echo "$selection" | cut -d: -f2)
            worktree_path=$(echo "$selection" | cut -d: -f3)
        elif [[ "$selection" == branch:* ]] || [[ "$selection" == remote:* ]]; then
            branch=$(echo "$selection" | cut -d: -f2)
        else
            exit 0
        fi
    fi

    # Ensure worktree exists (skip if we already have the path)
    if [[ -z "$worktree_path" ]]; then
        worktree_path=$(ensure_worktree "$branch")
    fi

    # Create the AI window
    create_ai_window "$worktree_path" "$branch"
}

main "$@"
