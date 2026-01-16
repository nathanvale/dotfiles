#!/bin/bash
# bin/tmux/worktree-ai.sh
# Create a git worktree and spawn a new tmux session with the standard template
#
# Usage: worktree-ai.sh [branch-name]
#   - With no args: shows fzf picker for existing worktrees/branches
#   - With branch name: creates new worktree or attaches to existing session
#
# Session naming: <repo>-wt-<branch> (e.g., dotfiles-wt-feat-auth)

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

# List ALL remote branches (as bases for new branches), newest first
list_remote_branches() {
    git branch -r --sort=-committerdate 2>/dev/null | grep -v HEAD | sed 's/.*origin\///' | while read -r branch; do
        echo "remote:$branch"
    done
}

# List ALL local branches (as bases for new branches), newest first
list_local_branches() {
    git branch --sort=-committerdate --format='%(refname:short)' | while read -r branch; do
        echo "local:$branch"
    done
}

# Show fzf picker for branch/worktree selection
pick_branch() {
    local choices=""

    # Header option to create new branch from HEAD
    choices="${CYAN}[+] Create new branch (from HEAD)${NC}\n"

    # Existing worktrees (can attach)
    local worktrees
    worktrees=$(list_worktrees)
    if [[ -n "$worktrees" ]]; then
        choices+="${GREEN}── Attach to Worktree ──${NC}\n"
        choices+="$worktrees\n"
    fi

    # Local branches as bases for new branches
    local local_branches
    local_branches=$(list_local_branches)
    if [[ -n "$local_branches" ]]; then
        choices+="${YELLOW}── New branch from Local ──${NC}\n"
        choices+="$local_branches\n"
    fi

    # Remote branches as bases for new branches
    local remote_branches
    remote_branches=$(list_remote_branches)
    if [[ -n "$remote_branches" ]]; then
        choices+="${BLUE}── New branch from Remote ──${NC}\n"
        choices+="$remote_branches\n"
    fi

    # Use fzf to pick (no --height in popup, it takes full space)
    local selection
    selection=$(echo -e "$choices" | fzf --ansi --reverse \
        --header="Select base branch or existing worktree" \
        --no-preview) || exit 0

    echo "$selection"
}

# Prompt for new branch name - sets REPLY variable directly
# Args: $1 = base branch (optional, for display)
prompt_new_branch() {
    local base="${1:-HEAD}"
    # After fzf exits, stdin might be weird - explicitly use /dev/tty
    exec < /dev/tty
    echo ""
    printf "${DIM}Base: ${base}${NC}\n"
    printf "${CYAN}Enter new branch name: ${NC}"
    read -r REPLY

    if [[ -z "$REPLY" ]]; then
        error "Branch name cannot be empty"
    fi

    # Sanitize branch name (allow slashes for feat/xxx style)
    REPLY=$(echo "$REPLY" | sed 's/[^a-zA-Z0-9._/-]/-/g')
}

# Create or get worktree path for a branch
# Args: $1 = new branch name, $2 = base branch (optional)
ensure_worktree() {
    local branch="$1"
    local base="${2:-}"
    local repo_root
    repo_root=$(get_repo_root)

    # Sanitize branch name for path (replace / with -)
    local path_safe_branch
    path_safe_branch=$(echo "$branch" | tr '/' '-')
    local worktree_path="$repo_root/$WORKTREE_DIR/$path_safe_branch"

    # Check if worktree already exists for this branch
    if git worktree list --porcelain | grep -q "^worktree $worktree_path$"; then
        echo "$worktree_path"
        return 0
    fi

    # Create worktrees directory if needed
    mkdir -p "$repo_root/$WORKTREE_DIR"

    # If base is specified, create new branch from that base
    if [[ -n "$base" ]]; then
        # Check if it's a remote base
        if [[ "$base" == origin/* ]] || git show-ref --verify --quiet "refs/remotes/origin/$base"; then
            local remote_ref="origin/$base"
            [[ "$base" == origin/* ]] && remote_ref="$base"
            info "Creating worktree: $branch from $remote_ref" >&2
            git worktree add -b "$branch" "$worktree_path" "$remote_ref" >&2
        else
            # Local base
            info "Creating worktree: $branch from $base" >&2
            git worktree add -b "$branch" "$worktree_path" "$base" >&2
        fi
    # No base specified - check if branch exists
    elif git show-ref --verify --quiet "refs/heads/$branch"; then
        info "Creating worktree for existing branch: $branch" >&2
        git worktree add "$worktree_path" "$branch" >&2
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        info "Creating worktree for remote branch: $branch" >&2
        git worktree add "$worktree_path" -b "$branch" "origin/$branch" >&2
    else
        # New branch from current HEAD
        info "Creating worktree with new branch: $branch (from HEAD)" >&2
        git worktree add -b "$branch" "$worktree_path" >&2
    fi

    echo "$worktree_path"
}

# Create tmux session with standard template (using raw tmux commands)
create_ai_session() {
    local worktree_path="$1"
    local branch="$2"
    local repo_name
    repo_name=$(basename "$(get_repo_root)")

    # Session name: repo-wt-branch (sanitized, kebab-case)
    local session_name
    session_name="${repo_name}-wt-$(echo "$branch" | tr '/' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-30)"

    # Check if session already exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
        success "Session '$session_name' exists, will switch to it..."
        # Write session name for wrapper to switch after popup closes
        if [[ -n "${WORKTREE_SWITCH_FILE:-}" ]]; then
            echo "$session_name" > "$WORKTREE_SWITCH_FILE"
        fi
        return
    fi

    info "Creating session '$session_name'..."

    # Create new detached session with 'ai' window
    tmux new-session -d -s "$session_name" -n "ai" -c "$worktree_path"

    # Split into 4 panes (tiled layout)
    tmux split-window -t "$session_name:ai" -h -c "$worktree_path"
    tmux split-window -t "$session_name:ai.1" -v -c "$worktree_path"
    tmux split-window -t "$session_name:ai.2" -v -c "$worktree_path"
    tmux select-layout -t "$session_name:ai" tiled

    # Start Claude in each pane with staggered delays
    tmux send-keys -t "$session_name:ai.1" "ccdev" C-m
    tmux send-keys -t "$session_name:ai.2" "sleep 2 && ccdev" C-m
    tmux send-keys -t "$session_name:ai.3" "sleep 4 && ccdev" C-m
    tmux send-keys -t "$session_name:ai.4" "sleep 6 && ccdev" C-m

    # Add git window with lazygit
    tmux new-window -t "$session_name" -n "git" -c "$worktree_path"
    tmux send-keys -t "$session_name:git" "lazygit" C-m

    # Add shell window
    tmux new-window -t "$session_name" -n "shell" -c "$worktree_path"

    # Select the ai window
    tmux select-window -t "$session_name:ai"
    tmux select-pane -t "$session_name:ai.1"

    success "Created session '$session_name' for worktree"
    echo ""
    echo "Worktree: $worktree_path"
    echo "Session:  $session_name"

    # Write session name for the wrapper to switch after popup closes
    if [[ -n "${WORKTREE_SWITCH_FILE:-}" ]]; then
        echo "$session_name" > "$WORKTREE_SWITCH_FILE"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    check_git_repo

    # Fetch latest from remote (prune deleted branches)
    info "Fetching latest from remote..."
    git fetch --prune --quiet 2>/dev/null || warning "Could not fetch from remote"

    local branch=""
    local worktree_path=""

    local base_branch=""

    if [[ -n "$1" ]]; then
        # Branch name provided as argument
        branch="$1"
    else
        # Show picker
        local selection
        selection=$(pick_branch)

        if [[ "$selection" == *"Create new branch"* ]]; then
            prompt_new_branch "HEAD"
            branch="$REPLY"
        elif [[ "$selection" == worktree:* ]]; then
            # Existing worktree - extract path and branch
            branch=$(echo "$selection" | cut -d: -f2)
            worktree_path=$(echo "$selection" | cut -d: -f3)
        elif [[ "$selection" == local:* ]]; then
            # Local branch selected as base - prompt for new branch name
            base_branch=$(echo "$selection" | cut -d: -f2)
            prompt_new_branch "$base_branch"
            branch="$REPLY"
        elif [[ "$selection" == remote:* ]]; then
            # Remote branch selected as base - prompt for new branch name
            base_branch=$(echo "$selection" | cut -d: -f2)
            prompt_new_branch "origin/$base_branch"
            branch="$REPLY"
        else
            exit 0
        fi
    fi

    # Ensure worktree exists (skip if we already have the path)
    if [[ -z "$worktree_path" ]]; then
        worktree_path=$(ensure_worktree "$branch" "$base_branch")
    fi

    # Create the AI session
    create_ai_session "$worktree_path" "$branch"
}

main "$@"
