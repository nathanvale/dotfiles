#!/usr/bin/env bash
# TaskDock worktree management
# Handles git worktree lifecycle for task-based development

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/git.sh"
source "${SCRIPT_DIR}/lib/locks.sh"

# ============================================================================
# SUBCOMMANDS
# ============================================================================

cmd_create() {
    local task_id="$1"
    local package_path="${2:-}"
    local skip_install=false

    # Parse flags
    shift 1
    [ -n "${2:-}" ] && shift 1
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-install)
                skip_install=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                return "$EXIT_INVALID_ARGS"
                ;;
        esac
    done

    info "Creating worktree for task ${task_id}..."

    # Get config values
    local worktree_root task_dir
    worktree_root="$(taskdock_config worktree_root)"
    task_dir="$(taskdock_config task_directory)"

    # Ensure we're in repo root
    local repo_root
    repo_root="$(get_repo_root)"
    cd "$repo_root"

    # Build worktree path
    local worktree_path="${worktree_root}/${task_id}"

    if [ -d "$worktree_path" ]; then
        error "Worktree already exists: ${worktree_path}"
        return "$EXIT_VALIDATION_FAILED"
    fi

    # Detect if monorepo
    local is_monorepo=false
    if [ -d "apps" ] || [ -d "packages" ]; then
        is_monorepo=true
        info "Monorepo detected"
    else
        info "Single repo detected"
    fi

    # Find task file
    local task_file_path=""
    if [ -n "$package_path" ]; then
        # Package explicitly specified
        task_file_path=$(find "$package_path" -path "*/docs/tasks/${task_id}-*.md" -o -path "*/tasks/${task_id}-*.md" 2>/dev/null | head -n 1 || true)
    elif [ "$is_monorepo" = true ]; then
        # Monorepo: search all packages
        task_file_path=$(find . -path "*/docs/tasks/${task_id}-*.md" -o -path "*/tasks/${task_id}-*.md" 2>/dev/null | head -n 1 || true)
    else
        # Single repo: search common locations
        task_file_path=$(find . -maxdepth 3 \( -path "*/docs/tasks/${task_id}-*.md" -o -path "*/tasks/${task_id}-*.md" -o -path "*/.tasks/${task_id}-*.md" \) 2>/dev/null | head -n 1 || true)
    fi

    if [ -z "$task_file_path" ]; then
        error "Task file not found for ${task_id}"
        tip "Searched in: docs/tasks/, tasks/, .tasks/"
        [ "$is_monorepo" = true ] && tip "Also searched: apps/*/docs/tasks/, packages/*/docs/tasks/"
        return "$EXIT_VALIDATION_FAILED"
    fi

    success "Found task file: ${task_file_path}"

    # Extract task title for branch name
    local task_title branch_name
    task_title=$(grep "^# " "$task_file_path" | head -n 1 | sed 's/^# //' | sed 's/^P[0-3]: //' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    branch_name="feat/${task_id}-${task_title}"

    info "Branch: ${branch_name}"

    # Check if lock exists (should from taskdock next)
    local lock_file
    lock_file="$(get_lock_dir)/${task_id}.lock"

    if [ ! -f "$lock_file" ]; then
        warn "No lock file found - creating one now"
        # Create lock manually (worktree creation can happen standalone)
        local now
        now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        jq -n \
            --arg taskId "$task_id" \
            --arg agentId "${TASKDOCK_CORRELATION_ID:-unknown}" \
            --arg hostname "$(hostname)" \
            --arg lockedAt "$now" \
            --arg heartbeatAt "$now" \
            --arg status "LOCKED" \
            --argjson pid "$$" \
            '{
                taskId: $taskId,
                agentId: $agentId,
                hostname: $hostname,
                lockedAt: $lockedAt,
                heartbeatAt: $heartbeatAt,
                status: $status,
                pid: $pid
            }' > "$lock_file"
    fi

    # Create new branch if it doesn't exist
    if ! git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
        git branch "$branch_name"
        info "Created branch: ${branch_name}"
    else
        info "Branch already exists: ${branch_name}"
    fi

    # Create worktree
    mkdir -p "$(dirname "$worktree_path")"
    git worktree add "$worktree_path" "$branch_name"

    success "Worktree created: ${worktree_path}"

    # Update lock with worktree metadata
    update_lock_heartbeat "$task_id"

    # Add worktree path and branch to lock
    local updated_lock
    updated_lock=$(jq \
        --arg worktree "$worktree_path" \
        --arg branch "$branch_name" \
        --arg taskFile "$task_file_path" \
        --arg status "IN_PROGRESS" \
        '. + {worktree: $worktree, branch: $branch, taskFile: $taskFile, status: $status}' \
        "$lock_file")
    echo "$updated_lock" > "$lock_file"

    # Install dependencies if needed
    if [ "$skip_install" = false ] && [ -f "${worktree_path}/package.json" ]; then
        info "Installing dependencies..."
        (cd "$worktree_path" && pnpm install) || warn "Dependency installation failed"
    fi

    log_task_event "worktree" "$task_id" "Worktree created" \
        "$(jq -n --arg path "$worktree_path" --arg branch "$branch_name" '{path: $path, branch: $branch}')"

    # Output result
    if [ "${TASKDOCK_OUTPUT:-human}" = "json" ]; then
        json_success "Worktree created" \
            "$(jq -n \
                --arg taskId "$task_id" \
                --arg path "$worktree_path" \
                --arg branch "$branch_name" \
                --arg taskFile "$task_file_path" \
                '{taskId: $taskId, path: $path, branch: $branch, taskFile: $taskFile}')"
    else
        success "Worktree ready at: ${worktree_path}"
        tip "Next: cd ${worktree_path}"
    fi
}

cmd_list() {
    info "Listing worktrees with lock status..."

    # Get main repo to skip it
    local main_repo
    main_repo="$(get_repo_root)"

    # Build JSON array of worktrees
    local worktrees_json="[]"

    while IFS= read -r line; do
        if [[ "$line" == worktree* ]]; then
            local worktree_path="${line#worktree }"

            # Skip main repo
            [ "$worktree_path" = "$main_repo" ] && continue

            # Skip if doesn't exist
            [ ! -d "$worktree_path" ] && continue

            # Get branch
            local branch
            branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

            # Extract task ID from path
            local task_id
            task_id=$(basename "$worktree_path")

            # Get lock info
            local lock_status="unlocked"
            local lock_data="{}"
            if is_task_locked "$task_id"; then
                lock_data="$(read_lock "$task_id")"
                lock_status="locked"
            fi

            # Get commit count
            local commit_count=0
            commit_count=$(git -C "$worktree_path" rev-list --count main..HEAD 2>/dev/null || echo "0")

            # Check for uncommitted changes
            local has_changes=false
            if [ -n "$(git -C "$worktree_path" status --porcelain 2>/dev/null)" ]; then
                has_changes=true
            fi

            # Add to array
            worktrees_json=$(echo "$worktrees_json" | jq \
                --arg taskId "$task_id" \
                --arg path "$worktree_path" \
                --arg branch "$branch" \
                --arg lockStatus "$lock_status" \
                --argjson lockData "$lock_data" \
                --argjson commitCount "$commit_count" \
                --argjson hasChanges "$has_changes" \
                '. + [{
                    taskId: $taskId,
                    path: $path,
                    branch: $branch,
                    lockStatus: $lockStatus,
                    lockData: $lockData,
                    commitCount: $commitCount,
                    hasChanges: $hasChanges
                }]')
        fi
    done < <(git worktree list --porcelain)

    if [ "${TASKDOCK_OUTPUT:-human}" = "json" ]; then
        json_success "Worktree list retrieved" "$worktrees_json"
    else
        # Human-readable output
        local count
        count=$(echo "$worktrees_json" | jq 'length')

        if [ "$count" -eq 0 ]; then
            info "No worktrees found"
            return 0
        fi

        echo ""
        echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
        echo -e "${COLOR_CYAN}Worktrees (${count} active)${COLOR_RESET}"
        echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
        echo ""

        echo "$worktrees_json" | jq -r '.[] |
            "Task: \(.taskId)\n" +
            "Path: \(.path)\n" +
            "Branch: \(.branch)\n" +
            "Lock: \(.lockStatus)\n" +
            "Commits: \(.commitCount)\n" +
            "Changes: \(if .hasChanges then "yes" else "no" end)\n"'
    fi
}

cmd_status() {
    local task_id="${1:-}"

    if [ -z "$task_id" ]; then
        # Show all worktrees
        cmd_list
        return 0
    fi

    # Show specific worktree status
    local worktree_root
    worktree_root="$(taskdock_config worktree_root)"
    local worktree_path="${worktree_root}/${task_id}"

    if [ ! -d "$worktree_path" ]; then
        error "Worktree not found for task: ${task_id}"
        return "$EXIT_VALIDATION_FAILED"
    fi

    # Gather status info
    local branch
    branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    local lock_status="unlocked"
    local lock_data="{}"
    if is_task_locked "$task_id"; then
        lock_data="$(read_lock "$task_id")"
        lock_status="locked"
    fi

    local commit_count
    commit_count=$(git -C "$worktree_path" rev-list --count main..HEAD 2>/dev/null || echo "0")

    local has_changes=false
    if [ -n "$(git -C "$worktree_path" status --porcelain 2>/dev/null)" ]; then
        has_changes=true
    fi

    if [ "${TASKDOCK_OUTPUT:-human}" = "json" ]; then
        json_success "Worktree status retrieved" \
            "$(jq -n \
                --arg taskId "$task_id" \
                --arg path "$worktree_path" \
                --arg branch "$branch" \
                --arg lockStatus "$lock_status" \
                --argjson lockData "$lock_data" \
                --argjson commitCount "$commit_count" \
                --argjson hasChanges "$has_changes" \
                '{
                    taskId: $taskId,
                    path: $path,
                    branch: $branch,
                    lockStatus: $lockStatus,
                    lockData: $lockData,
                    commitCount: $commitCount,
                    hasChanges: $hasChanges
                }')"
    else
        echo ""
        echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
        echo -e "${COLOR_CYAN}Worktree: ${task_id}${COLOR_RESET}"
        echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
        echo ""
        echo "Path:    ${worktree_path}"
        echo "Branch:  ${branch}"
        echo "Lock:    ${lock_status}"
        echo "Commits: ${commit_count}"
        echo "Changes: $([ "$has_changes" = true ] && echo "yes" || echo "no")"

        if [ "$has_changes" = true ]; then
            echo ""
            echo -e "${COLOR_YELLOW}Uncommitted changes:${COLOR_RESET}"
            git -C "$worktree_path" status --short | head -n 10
        fi

        if [ "$commit_count" -gt 0 ]; then
            echo ""
            echo "$(color_cyan "Recent commits:")"
            git -C "$worktree_path" log --oneline main..HEAD | head -n 5
        fi
    fi
}

cmd_cleanup() {
    local force=false
    local quiet=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force=true
                shift
                ;;
            --quiet)
                quiet=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                return "$EXIT_INVALID_ARGS"
                ;;
        esac
    done

    info "Cleaning up merged worktrees..."

    # Update refs from remote
    [ "$quiet" = false ] && info "Fetching latest changes..."
    git fetch --all --prune >/dev/null 2>&1 || true

    local main_repo
    main_repo="$(get_repo_root)"

    local cleaned_count=0
    local kept_count=0
    local failed_count=0

    while IFS= read -r line; do
        if [[ "$line" == worktree* ]]; then
            local worktree_path="${line#worktree }"

            # Skip main repo
            [ "$worktree_path" = "$main_repo" ] && continue

            # Skip if doesn't exist
            if [ ! -d "$worktree_path" ]; then
                [ "$quiet" = false ] && warn "Orphaned worktree metadata: ${worktree_path}"
                continue
            fi

            # Get branch
            local branch
            branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

            [ -z "$branch" ] && continue

            # Check if merged
            if git branch --merged main | grep -q "^[* ]*${branch}\$"; then
                [ "$quiet" = false ] && info "Branch ${branch} is merged - cleaning up..."

                # Extract task ID
                local task_id
                task_id=$(basename "$worktree_path")

                # Check for uncommitted changes
                if [ "$force" = false ] && [ -n "$(git -C "$worktree_path" status --porcelain 2>/dev/null)" ]; then
                    [ "$quiet" = false ] && warn "Skipping ${task_id} - has uncommitted changes (use --force to override)"
                    failed_count=$((failed_count + 1))
                    continue
                fi

                # Remove lock file
                delete_lock "$task_id" 2>/dev/null || true

                # Remove worktree
                if git worktree remove $([ "$force" = true ] && echo "--force") "$worktree_path" 2>/dev/null; then
                    [ "$quiet" = false ] && success "Removed worktree: ${task_id}"

                    # Delete branch
                    git branch -d "$branch" 2>/dev/null || git branch -D "$branch" 2>/dev/null || true

                    cleaned_count=$((cleaned_count + 1))
                    log_task_event "worktree" "$task_id" "Worktree cleaned up (merged)"
                else
                    [ "$quiet" = false ] && warn "Failed to remove worktree: ${task_id}"
                    failed_count=$((failed_count + 1))
                fi
            else
                kept_count=$((kept_count + 1))
            fi
        fi
    done < <(git worktree list --porcelain)

    # Prune stale worktree metadata
    git worktree prune >/dev/null 2>&1 || true

    if [ "${TASKDOCK_OUTPUT:-human}" = "json" ]; then
        json_success "Cleanup complete" \
            "$(jq -n \
                --argjson cleaned "$cleaned_count" \
                --argjson kept "$kept_count" \
                --argjson failed "$failed_count" \
                '{cleaned: $cleaned, kept: $kept, failed: $failed}')"
    else
        echo ""
        success "Cleanup complete"
        echo "  Cleaned: ${cleaned_count}"
        echo "  Kept:    ${kept_count}"
        echo "  Failed:  ${failed_count}"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local subcommand="${1:-}"

    if [ -z "$subcommand" ]; then
        error "Subcommand required"
        echo ""
        echo "Usage: taskdock worktree <subcommand> [options]"
        echo ""
        echo "Subcommands:"
        echo "  create <task-id> [package] [--no-install]  Create worktree for task"
        echo "  list                                        List all worktrees"
        echo "  status [task-id]                            Show worktree status"
        echo "  cleanup [--force] [--quiet]                 Clean up merged worktrees"
        echo ""
        echo "Examples:"
        echo "  taskdock worktree create T0001"
        echo "  taskdock worktree create T0001 apps/api --no-install"
        echo "  taskdock worktree list"
        echo "  taskdock worktree status T0001"
        echo "  taskdock worktree cleanup"
        return "$EXIT_INVALID_ARGS"
    fi

    shift

    case "$subcommand" in
        create)
            if [ $# -lt 1 ]; then
                error "Task ID required"
                tip "Usage: taskdock worktree create <task-id> [package] [--no-install]"
                return "$EXIT_INVALID_ARGS"
            fi
            cmd_create "$@"
            ;;
        list)
            cmd_list "$@"
            ;;
        status)
            cmd_status "$@"
            ;;
        cleanup)
            cmd_cleanup "$@"
            ;;
        *)
            error "Unknown subcommand: ${subcommand}"
            tip "Run 'taskdock worktree' to see available subcommands"
            return "$EXIT_INVALID_ARGS"
            ;;
    esac
}

main "$@"
