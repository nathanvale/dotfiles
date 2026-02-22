#!/bin/bash
# bin/tmux/worktree-delete.sh
# Delete git worktrees with smart multi-select UX
#
# Usage: worktree-delete.sh
#   - Shows fzf picker with TAB for multi-select
#   - Smart defaults: skip dirty, auto-delete merged branches
#
# Single worktree: full interactive flow with choices
# Multiple worktrees: smart batch with summary confirmation

WORKTREE_DIR=".worktrees"

# Field delimiter for internal data (Unit Separator - cannot appear in branch names or paths)
# Using \x1f instead of ~ because paths CAN contain tildes (e.g., /home/user/my~backup/)
D=$'\x1f'

# --- SideQuest CLI integration ---
COMMON="$(dirname "${BASH_SOURCE[0]}")/sidequest-common.sh"
if [[ -f "$COMMON" ]]; then
	source "$COMMON" || { USE_SIDEQUEST=0; echo "[worktree] sidequest-common.sh failed to source, falling back to native" >&2; }
else
	USE_SIDEQUEST=0
fi

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
is_worktree_clean() {
    local wt_path="$1"
    local status_output
    status_output=$(git -C "$wt_path" status --porcelain 2>/dev/null)
    [[ -z "$status_output" ]]
}

# Get branch status relative to main (returns: "pristine", "merged", "N ahead", or "unknown")
get_branch_status() {
    local branch="$1"

    # Validate branch exists
    if ! git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
        echo "unknown"
        return
    fi

    local main_branch

    # Try to get default branch from remote HEAD
    main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

    # If that failed, try common default branch names
    if [[ -z "$main_branch" ]]; then
        for try in main master develop; do
            if git show-ref --verify --quiet "refs/heads/$try"; then
                main_branch="$try"
                break
            fi
        done
    fi

    # If still no main branch found, return unknown
    if [[ -z "$main_branch" ]]; then
        echo "unknown"
        return
    fi

    # Count commits ahead of main
    local commits_ahead
    commits_ahead=$(git rev-list --count "$main_branch..$branch" 2>/dev/null)

    # If rev-list failed, return unknown
    if [[ -z "$commits_ahead" ]]; then
        echo "unknown"
        return
    fi

    if [[ "$commits_ahead" -eq 0 ]]; then
        echo "pristine"
    elif git branch --merged "$main_branch" 2>/dev/null | grep -qw "$branch"; then
        echo "merged"
    else
        echo "${commits_ahead} ahead"
    fi
}

# Check if branch is merged into main/master (for safe delete with -d vs -D)
is_branch_merged() {
    local status
    status=$(get_branch_status "$1")
    [[ "$status" == "pristine" || "$status" == "merged" ]]
}

# Get session name for a branch (must match create script)
get_session_name() {
    local branch="$1"
    local repo_name
    repo_name=$(basename "$(get_repo_root)")
    local safe_repo_name
    safe_repo_name=$(echo "$repo_name" | tr '.' '-')
    # Also replace dots in branch name (e.g., v1.2.3 -> v1-2-3) to match create script
    echo "${safe_repo_name}-wt-$(echo "$branch" | tr '/' '-' | tr '.' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-30)"
}

# Kill session if exists (with verification wait)
kill_session_if_exists() {
    local session_name="$1"
    local max_wait=10  # Maximum iterations to wait (10 * 0.1s = 1s max)
    local i=0

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        return 1  # Session doesn't exist
    fi

    tmux kill-session -t "$session_name" 2>/dev/null

    # Wait for session to actually be killed (with timeout)
    while tmux has-session -t "$session_name" 2>/dev/null; do
        i=$((i + 1))
        if [[ $i -ge $max_wait ]]; then
            warning "Session '$session_name' slow to terminate" >&2
            break
        fi
        sleep 0.1
    done
    return 0
}

# Get list of branches that have worktrees
get_worktree_branches() {
    git worktree list --porcelain | grep "^branch " | sed 's/^branch refs\/heads\///'
}

# Get default branch name
get_default_branch() {
    local main_branch
    main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

    if [[ -z "$main_branch" ]]; then
        for try in main master develop; do
            if git show-ref --verify --quiet "refs/heads/$try"; then
                main_branch="$try"
                break
            fi
        done
    fi

    echo "${main_branch:-main}"
}

# List worktrees with full status for fzf
list_worktrees_for_picker() {
    local repo_root
    repo_root=$(get_repo_root)

    git worktree list --porcelain | grep "^worktree " | cut -d' ' -f2- | while read -r wt; do
        # Skip main worktree
        if [[ "$wt" == "$repo_root" ]]; then
            continue
        fi

        local branch
        branch=$(git -C "$wt" branch --show-current 2>/dev/null || echo "detached")

        # Status indicators
        local clean_status branch_status
        if is_worktree_clean "$wt"; then
            clean_status="clean"
        else
            clean_status="dirty"
        fi

        branch_status=$(get_branch_status "$branch")

        # Format: worktree<D>branch<D>clean_status<D>branch_status<D>path
        echo "worktree${D}${branch}${D}${clean_status}${D}${branch_status}${D}${wt}"
    done
}

# List worktrees for picker via CLI (formats to match native output)
list_for_picker_cli() {
    local stderr_file
    stderr_file=$(mktemp)

    # Get worktree list
    local wt_json
    wt_json=$($SIDEQUEST_GIT_CMD worktree list --json 2>"$stderr_file") || {
        sidequest_log "cli" "list" "-" "$?" "$(cat "$stderr_file")"
        rm -f "$stderr_file"
        return 1
    }
    sidequest_log "cli" "list" "-" "0"

    # Get orphan branches
    local orphan_json
    orphan_json=$($SIDEQUEST_GIT_CMD worktree orphans --json 2>"$stderr_file") || {
        orphan_json="[]"  # Non-fatal, continue without orphans
    }
    sidequest_log "cli" "orphans" "-" "0"

    # Format worktrees for fzf (matching native format)
    # Native format: type<D>branch<D>clean_status<D>display_status<D>path
    echo "$wt_json" | jq -r --arg D "$D" '
        .[] | select(.isMain == false) |
        "worktree" + $D + .branch + $D +
        (if .dirty then "dirty" else "clean" end) + $D +
        (.status // "unknown") + $D + .path
    '

    # Format orphans
    echo "$orphan_json" | jq -r --arg D "$D" '
        .[] |
        "orphan" + $D + .branch + $D +
        (if .merged then "merged" else "unmerged" end) + $D +
        (.status // "unknown") + $D + "-"
    '

    rm -f "$stderr_file"
}

# List orphan branches (local branches without worktrees, excluding protected branches)
list_orphan_branches() {
    local default_branch
    default_branch=$(get_default_branch)

    local worktree_branches
    worktree_branches=$(get_worktree_branches)

    # Get all local branches
    git branch --format='%(refname:short)' | while read -r branch; do
        # Skip protected branches
        if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "develop" || "$branch" == "$default_branch" ]]; then
            continue
        fi

        # Skip if branch has a worktree
        if echo "$worktree_branches" | grep -qx "$branch"; then
            continue
        fi

        # Get branch status (pristine, merged, N ahead, or unknown)
        local branch_status
        branch_status=$(get_branch_status "$branch")

        # Format: orphan<D>branch<D>status
        echo "orphan${D}${branch}${D}${branch_status}"
    done
}

# Show fzf picker with multi-select
pick_worktrees() {
    local worktrees orphans

    # CLI dispatch for listing
    if [[ "${USE_SIDEQUEST:-0}" == "1" ]]; then
        # CLI function returns both worktrees and orphans in one call
        local combined
        combined=$(list_for_picker_cli 2>/dev/null | grep -v '^$' || true)
        worktrees=$(echo "$combined" | grep "^worktree${D}" || true)
        orphans=$(echo "$combined" | grep "^orphan${D}" || true)
    else
        worktrees=$(list_worktrees_for_picker 2>/dev/null | grep -v '^$' || true)
        orphans=$(list_orphan_branches 2>/dev/null | grep -v '^$' || true)
    fi

    # Check for actual content
    local has_worktrees has_orphans
    has_worktrees=$(echo "$worktrees" | grep -c "^worktree${D}" || true)
    has_orphans=$(echo "$orphans" | grep -c "^orphan${D}" || true)

    if [[ "$has_worktrees" -eq 0 && "$has_orphans" -eq 0 ]]; then
        echo "" >&2
        echo "No worktrees or orphan branches to delete" >&2
        echo "" >&2
        echo -n "Press Enter to close..." >&2
        exec < /dev/tty
        read -r
        exit 0
    fi

    # Build display list with sections
    local display_list=""

    # Worktrees section
    # Format: DATA<tab>DISPLAY where DATA=worktree<D>branch<D>path
    if [[ -n "$worktrees" ]]; then
        display_list+="${GREEN}── Worktrees ──${NC}\n"
        while IFS="$D" read -r type branch clean status path; do
            [[ -z "$branch" ]] && continue
            local clean_icon status_display

            if [[ "$clean" == "clean" ]]; then
                clean_icon="${GREEN}✓${NC}"
            else
                clean_icon="${YELLOW}⚠${NC}"
            fi

            # Status: pristine/merged = safe (dim), N ahead = warning (cyan)
            if [[ "$status" == "pristine" || "$status" == "merged" ]]; then
                status_display="${DIM}${status}${NC}"
            else
                status_display="${CYAN}${status}${NC}"
            fi

            # Tab-separated: DATA<tab>display (fzf --with-nth=2.. hides DATA)
            display_list+="$(printf "worktree${D}%s${D}%s\t%-35s %b %s %b" "$branch" "$path" "$branch" "$clean_icon" "$clean" "$status_display")\n"
        done <<< "$worktrees"
    fi

    # Orphan branches section
    if [[ -n "$orphans" ]]; then
        display_list+="${YELLOW}── Orphan Branches (no worktree) ──${NC}\n"
        while IFS="$D" read -r type branch status; do
            [[ -z "$branch" ]] && continue
            local status_display

            # Status: pristine/merged = safe (dim), N ahead = warning (cyan)
            if [[ "$status" == "pristine" || "$status" == "merged" ]]; then
                status_display="${DIM}${status}${NC}"
            else
                status_display="${CYAN}${status}${NC}"
            fi

            # Tab-separated: DATA<tab>display
            display_list+="$(printf "orphan${D}%s\t%-35s ${DIM}branch only${NC}  %b" "$branch" "$branch" "$status_display")\n"
        done <<< "$orphans"
    fi

    # Check if display_list has any actual items (not just headers)
    local has_items
    has_items=$(echo -e "$display_list" | grep -E "^(worktree${D}|orphan${D})" | head -1)

    if [[ -z "$has_items" ]]; then
        echo "" >&2
        echo "No worktrees or orphan branches to delete" >&2
        echo "" >&2
        echo -n "Press Enter to close..." >&2
        exec < /dev/tty
        read -r
        exit 0
    fi

    # Use fzf with multi-select, --with-nth=2.. hides the data field (shows only after tab)
    # Only include lines that start with worktree<D> or orphan<D> (actual selectable items)
    local fzf_input
    fzf_input=$(echo -e "$display_list" | grep -E "^(worktree${D}|orphan${D})")

    local selections
    selections=$(echo "$fzf_input" | fzf --ansi --reverse --multi \
        --delimiter=$'\t' --with-nth=2.. \
        --header="TAB to multi-select, Enter to confirm" \
        --preview-window=hidden) || exit 0

    # Return selections - extract data field (before tab)
    echo "$selections" | grep -E "^(worktree${D}|orphan${D})" | cut -f1
}

# Process multiple items (worktrees and orphan branches) with two-step flow
batch_delete() {
    local selections=("$@")

    # Categorize items
    # Format: wt_* arrays store "branch<D>path" for worktrees
    local wt_clean=()
    local wt_skipped_dirty=()
    local orphan_branches=()

    for selection in "${selections[@]}"; do
        # Parse selection: worktree<D>branch<D>path or orphan<D>branch
        if [[ "$selection" == worktree${D}* ]]; then
            local branch path
            branch=$(echo "$selection" | cut -d"$D" -f2)
            path=$(echo "$selection" | cut -d"$D" -f3)

            if ! is_worktree_clean "$path"; then
                wt_skipped_dirty+=("$branch${D}$path")
            else
                wt_clean+=("$branch${D}$path")
            fi
        elif [[ "$selection" == orphan${D}* ]]; then
            local branch
            branch=$(echo "$selection" | cut -d"$D" -f2)
            orphan_branches+=("$branch")
        fi
    done

    # ═══════════════════════════════════════════════════════════════════
    # STEP 1: Confirm worktree deletion
    # ═══════════════════════════════════════════════════════════════════
    echo ""
    echo -e "${BOLD}Step 1: Delete Worktrees${NC}"
    echo -e "${DIM}─────────────────────────────────────${NC}"

    if [[ ${#wt_clean[@]} -gt 0 ]]; then
        echo -e "${CYAN}Worktrees to delete:${NC}"
        for entry in "${wt_clean[@]}"; do
            echo -e "  • ${entry%%${D}*}"
        done
    fi

    if [[ ${#orphan_branches[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Orphan branches to delete:${NC}"
        for b in "${orphan_branches[@]}"; do
            local status
            status=$(get_branch_status "$b")
            if [[ "$status" == "pristine" || "$status" == "merged" ]]; then
                echo -e "  • $b (${DIM}${status}${NC})"
            else
                echo -e "  • $b (${CYAN}${status}${NC})"
            fi
        done
    fi

    if [[ ${#wt_skipped_dirty[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Skipped (dirty - delete individually):${NC}"
        for entry in "${wt_skipped_dirty[@]}"; do
            echo -e "  • ${entry%%${D}*}"
        done
    fi

    local total_step1=$((${#wt_clean[@]} + ${#orphan_branches[@]}))
    if [[ $total_step1 -eq 0 ]]; then
        echo ""
        warning "Nothing to delete (all selected worktrees are dirty)"
        echo -e "${DIM}Press Enter to close...${NC}"
        exec < /dev/tty
        read -r
        exit 0
    fi

    echo ""
    printf "${CYAN}Delete %d item(s)? [y/N]: ${NC}" "$total_step1"
    exec < /dev/tty
    read -r -n1 confirm
    echo ""

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        exit 0
    fi

    # Execute worktree deletions (keep branches for now)
    echo ""
    local deleted=0 failed=0
    local deleted_branches=()  # Track branches from deleted worktrees for step 2

    for entry in "${wt_clean[@]}"; do
        local branch="${entry%%${D}*}"
        local worktree_path="${entry#*${D}}"
        local session_name
        session_name=$(get_session_name "$branch")

        kill_session_if_exists "$session_name"

        local err
        if err=$(git worktree remove "$worktree_path" 2>&1); then
            success "✓ $branch (worktree removed)"
            deleted=$((deleted + 1))
            deleted_branches+=("$branch")
        else
            warning "✗ $branch (failed: $err)"
            failed=$((failed + 1))
        fi
    done

    # Delete orphan branches
    for branch in "${orphan_branches[@]}"; do
        local err delete_flag="-d"
        is_branch_merged "$branch" || delete_flag="-D"

        if err=$(git branch "$delete_flag" "$branch" 2>&1); then
            success "✓ $branch (branch deleted)"
            deleted=$((deleted + 1))
        else
            warning "✗ $branch (failed: $err)"
            failed=$((failed + 1))
        fi
    done

    echo ""
    echo -e "${GREEN}Deleted: $deleted${NC}  ${RED}Failed: $failed${NC}  ${YELLOW}Skipped: ${#wt_skipped_dirty[@]}${NC}"

    # ═══════════════════════════════════════════════════════════════════
    # STEP 2: Optionally delete branches from removed worktrees
    # ═══════════════════════════════════════════════════════════════════
    if [[ ${#deleted_branches[@]} -eq 0 ]]; then
        return
    fi

    echo ""
    echo -e "${BOLD}Step 2: Delete Branches?${NC}"
    echo -e "${DIM}─────────────────────────────────────${NC}"
    echo -e "The following branches still exist:"

    # Build branch list for fzf (tab-separated: branch<tab>display)
    local branch_list=""
    for branch in "${deleted_branches[@]}"; do
        [[ -z "$branch" ]] && continue
        local status status_display
        status=$(get_branch_status "$branch")

        # Status: pristine/merged = safe (dim), N ahead = warning (cyan)
        if [[ "$status" == "pristine" || "$status" == "merged" ]]; then
            status_display="${DIM}${status}${NC}"
        else
            status_display="${CYAN}${status}${NC}"
        fi
        branch_list+=$(printf "%s\t%-35s  %b\n" "$branch" "$branch" "$status_display")
        branch_list+="\n"
    done

    echo ""
    echo -e "${DIM}TAB to select branches to delete, Enter to confirm (or Enter with none to keep all)${NC}"
    echo ""

    local branch_selections
    branch_selections=$(echo -e "$branch_list" | grep -v '^$' | fzf --ansi --reverse --multi \
        --delimiter=$'\t' --with-nth=2.. \
        --header="Select branches to delete (TAB=select, Enter=confirm)" \
        --preview-window=hidden) || true

    if [[ -z "$branch_selections" ]]; then
        info "Keeping all branches"
        return
    fi

    # Delete selected branches
    local branch_deleted=0 branch_failed=0
    while IFS= read -r line; do
        local branch
        branch=$(echo "$line" | cut -f1)  # Extract branch name (before tab)
        [[ -z "$branch" ]] && continue

        local err delete_flag="-d"
        is_branch_merged "$branch" || delete_flag="-D"

        if err=$(git branch "$delete_flag" "$branch" 2>&1); then
            success "✓ $branch (branch deleted)"
            branch_deleted=$((branch_deleted + 1))
        else
            warning "✗ $branch (failed: $err)"
            branch_failed=$((branch_failed + 1))
        fi
    done <<< "$branch_selections"

    echo ""
    echo -e "${GREEN}Branches deleted: $branch_deleted${NC}  ${RED}Failed: $branch_failed${NC}"
}

# Process multiple items via CLI (worktrees and orphan branches)
batch_delete_cli() {
    local -a selections=("$@")
    local total=${#selections[@]}
    local succeeded=0
    local failed=0
    local -a failed_items=()
    local -a deleted_branches=()
    local stderr_file
    stderr_file=$(mktemp)

    # Phase 1: Remove all worktrees
    info "Removing $total worktree(s)..."
    for item in "${selections[@]}"; do
        local item_type item_branch item_path
        item_type=$(echo "$item" | cut -d"$D" -f1)
        item_branch=$(echo "$item" | cut -d"$D" -f2)
        item_path=$(echo "$item" | cut -d"$D" -f5)

        if [[ "$item_type" == "orphan" ]]; then
            # Orphans are just branches, handle in phase 2
            deleted_branches+=("$item_branch")
            continue
        fi

        # Kill tmux session if it exists
        local session_name
        session_name=$(get_session_name "$item_branch")
        kill_session_if_exists "$session_name"

        # Delete worktree via CLI
        local delete_output
        delete_output=$($SIDEQUEST_GIT_CMD worktree delete "$item_branch" --json 2>"$stderr_file")
        local exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            ((succeeded++))
            sidequest_log "cli" "delete" "$item_branch" "0"
            deleted_branches+=("$item_branch")
            success "Removed worktree: $item_branch"
        else
            ((failed++))
            local err_msg
            err_msg=$(jq -r '.error // "unknown error"' <<< "$(cat "$stderr_file")" 2>/dev/null || cat "$stderr_file")
            failed_items+=("$item_branch: $err_msg")
            sidequest_log "cli" "delete" "$item_branch" "$exit_code" "$err_msg"
            warning "Failed to remove: $item_branch - $err_msg"
        fi
    done

    # Phase 2: Branch deletion picker (if any branches to delete)
    if [[ ${#deleted_branches[@]} -gt 0 ]]; then
        echo ""
        info "Worktrees removed. Delete associated branches?"
        # Present branches for deletion using existing branch deletion logic
        for branch in "${deleted_branches[@]}"; do
            if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
                local default_branch
                default_branch=$(get_default_branch)
                if is_branch_merged "$branch" "$default_branch"; then
                    read -rp "  Delete merged branch '$branch'? [Y/n] " confirm
                    if [[ "${confirm:-Y}" =~ ^[Yy]?$ ]]; then
                        git branch -d "$branch" 2>/dev/null && success "Deleted branch: $branch" || error "Failed to delete branch: $branch"
                    fi
                else
                    read -rp "  Force-delete unmerged branch '$branch'? [y/N] " confirm
                    if [[ "${confirm}" =~ ^[Yy]$ ]]; then
                        git branch -D "$branch" 2>/dev/null && success "Deleted branch: $branch" || error "Failed to delete branch: $branch"
                    fi
                fi
            fi
        done
    fi

    # Print summary
    echo ""
    info "Summary: $succeeded succeeded, $failed failed out of $total"
    if [[ ${#failed_items[@]} -gt 0 ]]; then
        warning "Failed items:"
        for item in "${failed_items[@]}"; do
            echo "  - $item" >&2
        done
    fi

    rm -f "$stderr_file"
    [[ $failed -eq 0 ]]
}

# Delete a single orphan branch with confirmation
delete_orphan_branch() {
    local branch="$1"
    local is_merged
    is_merged=$(is_branch_merged "$branch" && echo "yes" || echo "no")

    echo ""
    echo -e "${BOLD}Delete orphan branch: ${CYAN}$branch${NC}"
    echo -e "  Status: $([[ $is_merged == "yes" ]] && echo "${DIM}merged${NC}" || echo "${YELLOW}unmerged${NC}")"
    echo ""

    if [[ "$is_merged" == "no" ]]; then
        warning "⚠ Branch has unmerged commits!"
        printf "${RED}Force delete? [y/N]: ${NC}"
        exec < /dev/tty
        read -r -n1 confirm
        echo ""
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Cancelled."
            exit 0
        fi
        if git branch -D "$branch" 2>/dev/null; then
            success "✓ Deleted: $branch (force)"
        else
            error "Failed to delete branch"
        fi
    else
        printf "${CYAN}Delete branch? [y/N]: ${NC}"
        exec < /dev/tty
        read -r -n1 confirm
        echo ""
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Cancelled."
            exit 0
        fi
        if git branch -d "$branch" 2>/dev/null; then
            success "✓ Deleted: $branch"
        else
            error "Failed to delete branch"
        fi
    fi
}

# Single item delete with full interactive flow
single_delete() {
    local selection="$1"

    # Handle orphan branch deletion (format: orphan<D>branch)
    if [[ "$selection" == orphan${D}* ]]; then
        local branch
        branch=$(echo "$selection" | cut -d"$D" -f2)
        delete_orphan_branch "$branch"
        return
    fi

    # Parse worktree selection (format: worktree<D>branch<D>path)
    local branch worktree_path
    branch=$(echo "$selection" | cut -d"$D" -f2)
    worktree_path=$(echo "$selection" | cut -d"$D" -f3)

    # Verify worktree exists
    if [[ ! -d "$worktree_path" ]]; then
        error "Worktree not found: $worktree_path"
    fi

    local session_name
    session_name=$(get_session_name "$branch")

    # Get status
    local is_clean is_merged
    is_clean=$(is_worktree_clean "$worktree_path" && echo "yes" || echo "no")
    is_merged=$(is_branch_merged "$branch" && echo "yes" || echo "no")

    echo ""
    echo -e "${BOLD}Delete worktree: ${CYAN}$branch${NC}"
    echo -e "  Path:    $worktree_path"
    echo -e "  Session: $session_name"
    echo -e "  Status:  $([[ $is_clean == "yes" ]] && echo "${GREEN}clean${NC}" || echo "${YELLOW}dirty${NC}")"
    echo -e "  Branch:  $([[ $is_merged == "yes" ]] && echo "${DIM}merged${NC}" || echo "${CYAN}unmerged${NC}")"
    echo ""

    # Warn if dirty
    if [[ "$is_clean" == "no" ]]; then
        warning "⚠ Worktree has uncommitted changes:"
        git -C "$worktree_path" status --short 2>/dev/null | head -5
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

    # Ask about branch
    printf "${CYAN}[D]elete worktree only  [B]ranch too  [C]ancel: ${NC}"
    exec < /dev/tty
    read -r -n1 delete_choice
    echo ""

    local delete_branch=false
    case "$delete_choice" in
        b|B)
            delete_branch=true
            if [[ "$is_merged" == "no" ]]; then
                warning "⚠ Branch has unmerged commits!"
                printf "${RED}Force delete branch? [y/N]: ${NC}"
                exec < /dev/tty
                read -r -n1 unmerged_choice
                echo ""
                if [[ "$unmerged_choice" != "y" && "$unmerged_choice" != "Y" ]]; then
                    delete_branch=false
                fi
            fi
            ;;
        d|D)
            ;;
        *)
            echo "Cancelled."
            exit 0
            ;;
    esac

    # Execute
    kill_session_if_exists "$session_name" && info "Killed session: $session_name"

    info "Removing worktree..."
    git worktree remove ${force_flag:+"$force_flag"} "$worktree_path"

    if [[ "$delete_branch" == true ]]; then
        info "Deleting branch..."
        git branch -D "$branch" 2>/dev/null || warning "Could not delete branch"
    fi

    success "✓ Deleted: $branch"
}

# Single item delete via CLI with full interactive flow
single_delete_cli() {
    local selection="$1"
    local stderr_file
    stderr_file=$(mktemp)

    # Parse selection to get branch name
    local branch
    if [[ "$selection" == orphan${D}* ]]; then
        # Orphan branch: orphan<D>branch
        branch=$(echo "$selection" | cut -d"$D" -f2)
    else
        # Worktree: worktree<D>branch<D>clean<D>status<D>path
        branch=$(echo "$selection" | cut -d"$D" -f2)
    fi

    # Pre-delete check via CLI
    local check_output
    check_output=$($SIDEQUEST_GIT_CMD worktree check "$branch" --json 2>"$stderr_file")
    local check_exit=$?

    if [[ $check_exit -ne 0 ]]; then
        local err_msg
        err_msg=$(jq -r '.error // "unknown error"' <<< "$(cat "$stderr_file")" 2>/dev/null || cat "$stderr_file")
        sidequest_error "check" "$err_msg" "$SIDEQUEST_GIT_CMD worktree check \"$branch\" --json"
        rm -f "$stderr_file"
        return 1
    fi

    # Display status from check
    local dirty merged exists
    dirty=$(jq -r '.dirty' <<< "$check_output")
    merged=$(jq -r '.merged' <<< "$check_output")
    exists=$(jq -r '.exists' <<< "$check_output")

    # If it's an orphan branch (no worktree), just delete the branch
    if [[ "$exists" != "true" ]]; then
        info "Branch: $branch (orphan)"

        if [[ "$merged" == "true" ]]; then
            read -rp "Delete merged branch '$branch'? [Y/n] " confirm
            [[ "${confirm:-Y}" =~ ^[Yy]?$ ]] || { rm -f "$stderr_file"; return 0; }
            git branch -d "$branch" 2>/dev/null && success "Deleted branch: $branch" || error "Failed to delete branch: $branch"
        else
            read -rp "Force-delete unmerged branch '$branch'? [y/N] " confirm
            [[ "${confirm}" =~ ^[Yy]$ ]] || { rm -f "$stderr_file"; return 0; }
            git branch -D "$branch" 2>/dev/null && success "Deleted branch: $branch" || error "Failed to delete branch: $branch"
        fi
        rm -f "$stderr_file"
        return 0
    fi

    # Show status and confirm for worktree deletion
    local status_display=""
    [[ "$dirty" == "true" ]] && status_display+="dirty "
    [[ "$merged" == "true" ]] && status_display+="merged "
    [[ -z "$status_display" ]] && status_display="clean "

    info "Branch: $branch (${status_display% })"

    local force_flag=""
    if [[ "$dirty" == "true" ]]; then
        warning "Worktree has uncommitted changes"
        read -rp "Force delete? [y/N] " confirm
        [[ "${confirm}" =~ ^[Yy]$ ]] || { rm -f "$stderr_file"; return 0; }
        force_flag="--force"
    fi

    # Kill tmux session
    local session_name
    session_name=$(get_session_name "$branch")
    kill_session_if_exists "$session_name"

    # Delete via CLI
    local delete_output
    delete_output=$($SIDEQUEST_GIT_CMD worktree delete "$branch" $force_flag --json 2>"$stderr_file")
    local delete_exit=$?

    if [[ $delete_exit -ne 0 ]]; then
        local err_msg
        err_msg=$(jq -r '.error // "unknown error"' <<< "$(cat "$stderr_file")" 2>/dev/null || cat "$stderr_file")
        sidequest_error "delete" "$err_msg" "$SIDEQUEST_GIT_CMD worktree delete \"$branch\" $force_flag --json" "git worktree remove --force \"$(jq -r '.path' <<< "$check_output")\""
        sidequest_log "cli" "delete" "$branch" "$delete_exit" "$err_msg"
        rm -f "$stderr_file"
        return 1
    fi

    sidequest_log "cli" "delete" "$branch" "0"
    success "Removed worktree: $branch"

    # Ask about branch deletion
    if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
        local default_branch
        default_branch=$(get_default_branch)
        if is_branch_merged "$branch" "$default_branch"; then
            read -rp "Delete merged branch '$branch'? [Y/n] " confirm
            [[ "${confirm:-Y}" =~ ^[Yy]?$ ]] && git branch -d "$branch" 2>/dev/null
        else
            read -rp "Force-delete unmerged branch '$branch'? [y/N] " confirm
            [[ "${confirm}" =~ ^[Yy]$ ]] && git branch -D "$branch" 2>/dev/null
        fi
    fi

    rm -f "$stderr_file"
}

# Main
main() {
    if ! git rev-parse --git-dir &>/dev/null; then
        error "Not in a git repository"
    fi

    # SideQuest CLI dispatch - preflight check
    if [[ "${USE_SIDEQUEST:-0}" == "1" ]]; then
        sidequest_preflight
    fi

    # Auto-prune stale entries
    git worktree prune 2>/dev/null || true

    # Get selections (format: "worktree|branch|path" or "orphan:branch")
    local selections
    selections=$(pick_worktrees)

    if [[ -z "$selections" ]]; then
        exit 0
    fi

    # Convert to array
    local -a items
    while IFS= read -r item; do
        [[ -n "$item" ]] && items+=("$item")
    done <<< "$selections"

    # Single vs batch - dispatch to CLI variants if enabled
    if [[ ${#items[@]} -eq 1 ]]; then
        if [[ "${USE_SIDEQUEST:-0}" == "1" ]]; then
            single_delete_cli "${items[0]}"
        else
            single_delete "${items[0]}"
        fi
    else
        if [[ "${USE_SIDEQUEST:-0}" == "1" ]]; then
            batch_delete_cli "${items[@]}"
        else
            batch_delete "${items[@]}"
        fi
    fi
}

main "$@"
