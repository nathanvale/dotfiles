#!/bin/bash
# bin/tmux/worktree-delete.sh
# Delete a git worktree with smart UX - handles sessions, branches, uncommitted changes
#
# Usage: worktree-delete.sh [branch-name]
#   - With no args: shows fzf picker with status indicators
#   - With branch name: deletes that worktree directly (with confirmation)

set -e

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

info() { printf "${BLUE}%s${NC}\n" "$1"; }
success() { printf "${GREEN}%s${NC}\n" "$1"; }
warning() { printf "${YELLOW}%s${NC}\n" "$1"; }
error() { printf "${RED}%s${NC}\n" "$1" >&2; exit 1; }

# Get the root of the main worktree
get_repo_root() {
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    if [[ "$git_common_dir" == ".git" ]]; then
        pwd
    else
        dirname "$git_common_dir"
    fi
}

# Check if worktree is clean (no uncommitted changes)
get_worktree_status() {
    local wt_path="$1"
    local status_output
    status_output=$(git -C "$wt_path" status --porcelain 2>/dev/null)

    if [[ -z "$status_output" ]]; then
        echo "clean"
    else
        local count
        count=$(echo "$status_output" | wc -l | tr -d ' ')
        echo "$count changes"
    fi
}

# Check if session exists for this worktree
get_session_status() {
    local branch="$1"
    local repo_name
    repo_name=$(basename "$(get_repo_root)")
    local session_name="${repo_name}-wt-$(echo "$branch" | tr '/' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-30)"

    if tmux has-session -t "$session_name" 2>/dev/null; then
        local current_session
        current_session=$(tmux display-message -p '#S' 2>/dev/null || echo "")
        if [[ "$current_session" == "$session_name" ]]; then
            echo "active:$session_name"
        else
            echo "running:$session_name"
        fi
    else
        echo "none:"
    fi
}

# Check if branch is merged into main/master
is_branch_merged() {
    local branch="$1"
    local main_branch
    main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

    if git branch --merged "$main_branch" 2>/dev/null | grep -qw "$branch"; then
        echo "merged"
    else
        echo "unmerged"
    fi
}

# List worktrees with status for fzf
list_worktrees_with_status() {
    local repo_root
    repo_root=$(get_repo_root)

    git worktree list --porcelain | grep "^worktree " | cut -d' ' -f2- | while read -r wt; do
        # Skip main worktree
        if [[ "$wt" == "$repo_root" ]]; then
            continue
        fi

        local branch
        branch=$(git -C "$wt" branch --show-current 2>/dev/null || echo "detached")

        local wt_status
        wt_status=$(get_worktree_status "$wt")

        local session_info
        session_info=$(get_session_status "$branch")
        local session_status="${session_info%%:*}"

        # Format: branch|status|session|path
        echo "${branch}|${wt_status}|${session_status}|${wt}"
    done
}

# Show fzf picker for worktree selection
pick_worktree() {
    local worktrees
    worktrees=$(list_worktrees_with_status)

    if [[ -z "$worktrees" ]]; then
        error "No worktrees to delete"
    fi

    # Format for display
    local display_list
    display_list=$(echo "$worktrees" | while IFS='|' read -r branch status session path; do
        local status_icon session_icon

        if [[ "$status" == "clean" ]]; then
            status_icon="${GREEN}✓ clean${NC}"
        else
            status_icon="${YELLOW}⚠ ${status}${NC}"
        fi

        case "$session" in
            active)  session_icon="${RED}● active${NC}" ;;
            running) session_icon="${BLUE}○ session${NC}" ;;
            *)       session_icon="${DIM}no session${NC}" ;;
        esac

        printf "%-25s %s  %s\n" "$branch" "$status_icon" "$session_icon"
    done)

    local selection
    selection=$(echo -e "$display_list" | fzf --ansi --reverse \
        --header="Select worktree to delete (Esc to cancel)" \
        --no-preview) || exit 0

    # Extract branch name from selection
    echo "$selection" | awk '{print $1}'
}

# Confirm and delete worktree
delete_worktree() {
    local branch="$1"
    local repo_root
    repo_root=$(get_repo_root)
    local worktree_path="$repo_root/$WORKTREE_DIR/$branch"

    # Verify worktree exists
    if ! git worktree list --porcelain | grep -q "^worktree $worktree_path$"; then
        error "Worktree not found: $branch"
    fi

    local repo_name
    repo_name=$(basename "$repo_root")
    local session_name="${repo_name}-wt-$(echo "$branch" | tr '/' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-30)"

    # Get status info
    local wt_status
    wt_status=$(get_worktree_status "$worktree_path")

    local session_info
    session_info=$(get_session_status "$branch")
    local session_status="${session_info%%:*}"

    local merge_status
    merge_status=$(is_branch_merged "$branch")

    echo ""
    echo -e "${BOLD}Delete worktree: ${CYAN}$branch${NC}"
    echo -e "  Worktree: $worktree_path"
    echo -e "  Session:  $session_name"
    echo -e "  Branch:   $branch ($merge_status)"
    echo ""

    # Check for uncommitted changes
    if [[ "$wt_status" != "clean" ]]; then
        warning "⚠ Worktree has uncommitted changes:"
        git -C "$worktree_path" status --short 2>/dev/null | head -10
        echo ""
        printf "${YELLOW}[F]orce delete  [C]ancel: ${NC}"
        exec < /dev/tty
        read -r -n1 force_choice
        echo ""
        if [[ "$force_choice" != "f" && "$force_choice" != "F" ]]; then
            echo "Cancelled."
            exit 0
        fi
        local force_flag="--force"
    else
        local force_flag=""
    fi

    # Check if active session
    if [[ "$session_status" == "active" ]]; then
        warning "⚠ You're currently IN this session!"
        printf "${YELLOW}Will switch to main session before deleting. Continue? [y/N]: ${NC}"
        exec < /dev/tty
        read -r -n1 active_choice
        echo ""
        if [[ "$active_choice" != "y" && "$active_choice" != "Y" ]]; then
            echo "Cancelled."
            exit 0
        fi
        # Switch to main repo session first
        local main_session="$repo_name"
        if tmux has-session -t "$main_session" 2>/dev/null; then
            tmux switch-client -t "$main_session"
        fi
    fi

    # Ask about branch deletion
    printf "${CYAN}[D]elete worktree only  [B]ranch too  [C]ancel: ${NC}"
    exec < /dev/tty
    read -r -n1 delete_choice
    echo ""

    case "$delete_choice" in
        d|D)
            local delete_branch=false
            ;;
        b|B)
            local delete_branch=true
            if [[ "$merge_status" == "unmerged" ]]; then
                warning "⚠ Branch has unmerged commits!"
                printf "${RED}Are you sure? [y/N]: ${NC}"
                exec < /dev/tty
                read -r -n1 unmerged_choice
                echo ""
                if [[ "$unmerged_choice" != "y" && "$unmerged_choice" != "Y" ]]; then
                    echo "Cancelled."
                    exit 0
                fi
            fi
            ;;
        *)
            echo "Cancelled."
            exit 0
            ;;
    esac

    # Kill tmux session if exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
        info "Killing session: $session_name"
        tmux kill-session -t "$session_name" 2>/dev/null || true
    fi

    # Remove worktree
    info "Removing worktree: $worktree_path"
    git worktree remove $force_flag "$worktree_path"

    # Delete branch if requested
    if [[ "$delete_branch" == true ]]; then
        info "Deleting branch: $branch"
        git branch -D "$branch" 2>/dev/null || warning "Could not delete branch (may be checked out elsewhere)"
    fi

    success "✓ Deleted worktree: $branch"
}

# Main
main() {
    # Check we're in a git repo
    if ! git rev-parse --git-dir &>/dev/null; then
        error "Not in a git repository"
    fi

    # Auto-prune stale worktree entries (silent cleanup)
    git worktree prune 2>/dev/null || true

    local branch=""

    if [[ -n "$1" ]]; then
        # Branch provided as argument
        branch="$1"
    else
        # Show picker
        branch=$(pick_worktree)
        if [[ -z "$branch" ]]; then
            exit 0
        fi
    fi

    delete_worktree "$branch"
}

main "$@"
