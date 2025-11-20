#!/bin/bash
# Get Next Task Number (Shared Counter Across Worktrees)
#
# Maintains a counter in .git/task-counter that's shared by all worktrees
# of the same repository. This ensures task numbers are globally unique.
#
# Usage:
#   source ~/.claude/scripts/lib/get-next-task-number.sh
#   NEXT_NUM=$(get_next_task_number "/path/to/tasks" "MPCU-")
#
# Arguments:
#   $1 - Task directory path (used to find repo root)
#   $2 - Task prefix (e.g., "MPCU-", "T-", "TASK-")
#
# Returns:
#   Next available task number (e.g., "0100", "0045")

get_next_task_number() {
    local task_dir="$1"
    local prefix="$2"
    
    # Get the COMMON .git directory (shared across all worktrees)
    local git_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    if [ -z "$git_dir" ]; then
        echo "0001"
        return
    fi
    
    # Counter file in .git directory - shared by all worktrees!
    local counter_file="$git_dir/task-counter"
    
    # Lock file to prevent race conditions between parallel task creations
    local lock_file="$git_dir/task-counter.lock"
    
    # Acquire lock (wait up to 5 seconds)
    local count=0
    while [ -f "$lock_file" ] && [ $count -lt 50 ]; do
        sleep 0.1
        count=$((count + 1))
    done
    
    # Create lock
    echo $$ > "$lock_file"
    
    # Initialize counter if it doesn't exist
    if [ ! -f "$counter_file" ]; then
        # Start at 1, or scan existing tasks to find highest
        local repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
        local highest=0
        
        # Check main branch for existing tasks
        if [ -n "$repo_root" ]; then
            highest=$(git ls-tree -r HEAD --name-only 2>/dev/null | \
                grep "${prefix}[0-9]" | \
                sed "s/.*${prefix}\([0-9]*\).*/\1/" | \
                sort -n | tail -1)
        fi
        
        if [ -z "$highest" ] || [ "$highest" -eq 0 ]; then
            echo "1" > "$counter_file"
        else
            echo "$((highest + 1))" > "$counter_file"
        fi
    fi
    
    # Read and increment counter
    local current_num=$(cat "$counter_file")
    local next_num=$((current_num + 1))
    echo "$next_num" > "$counter_file"
    
    # Release lock
    rm -f "$lock_file"
    
    # Return formatted current number
    printf "%04d" "$current_num"
}