#!/usr/bin/env bash
# TaskDock merge - Merge PR and cleanup worktree
# Supports GitHub and Azure DevOps with automatic detection

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/git.sh"
source "${SCRIPT_DIR}/lib/locks.sh"

# Track merge success for cleanup
MERGE_SUCCEEDED=false
TASK_ID=""

cleanup_on_exit() {
    local exit_code=$?

    # Only unlock if merge succeeded
    if [ "$MERGE_SUCCEEDED" = true ] && [ -n "$TASK_ID" ]; then
        delete_lock "$TASK_ID" 2>/dev/null || true
    fi

    exit $exit_code
}

trap cleanup_on_exit EXIT INT TERM

# ============================================================================
# SUBCOMMANDS
# ============================================================================

cmd_pr() {
    local pr_input="${1:-}"
    local force_current=false

    # Parse flags
    shift || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --current)
                force_current=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                return "$EXIT_INVALID_ARGS"
                ;;
        esac
    done

    info "Detecting Git provider..."
    local provider
    provider=$(detect_git_provider)
    success "Detected: ${provider}"

    # Identify PR and branch
    info "Identifying PR and branch..."
    local pr_number="" pr_id="" branch_name=""

    if [ "$provider" = "github" ]; then
        # GitHub workflow
        if [ "$force_current" = true ] || [ -z "$pr_input" ]; then
            # Use current branch
            branch_name=$(git branch --show-current)
            info "Current branch: ${branch_name}"

            local pr_json
            pr_json=$(gh pr list --head "$branch_name" --json number,headRefName --limit 1)
            pr_number=$(echo "$pr_json" | jq -r '.[0].number // empty')

            if [ -z "$pr_number" ]; then
                error "No PR found for branch: ${branch_name}"
                return "$EXIT_VALIDATION_FAILED"
            fi
        elif [[ "$pr_input" =~ ^[0-9]+$ ]]; then
            # PR number provided
            pr_number="$pr_input"
            branch_name=$(gh pr view "$pr_number" --json headRefName -q .headRefName)
        elif [[ "$pr_input" =~ ^[A-Z][A-Z0-9-]*[0-9]+$ ]]; then
            # Task ID provided
            TASK_ID="$pr_input"
            info "Looking for task: ${TASK_ID}"

            branch_name=$(git branch --list "feat/${TASK_ID}-*" --format='%(refname:short)' | head -1)

            if [ -z "$branch_name" ]; then
                error "No branch found for task: ${TASK_ID}"
                return "$EXIT_VALIDATION_FAILED"
            fi

            pr_number=$(gh pr list --head "$branch_name" --json number -q '.[0].number')

            if [ -z "$pr_number" ]; then
                error "No PR found for branch: ${branch_name}"
                return "$EXIT_VALIDATION_FAILED"
            fi
        else
            error "Invalid input: ${pr_input}"
            tip "Usage: taskdock merge pr [PR_NUMBER | TASK_ID | --current]"
            return "$EXIT_INVALID_ARGS"
        fi

        success "PR #${pr_number}"
        success "Branch: ${branch_name}"

        # Verify PR status
        info "Verifying PR status..."
        local pr_data
        pr_data=$(gh pr view "$pr_number" --json state,mergeable,reviewDecision,title)

        local state mergeable review pr_title
        read -r state mergeable review pr_title < <(echo "$pr_data" | jq -r '[.state, .mergeable, .reviewDecision, .title] | @tsv')

        info "State: ${state}, Mergeable: ${mergeable}, Review: ${review}"

        if [ "$state" != "OPEN" ]; then
            error "PR #${pr_number} is not open (state: ${state})"
            return "$EXIT_VALIDATION_FAILED"
        fi

        if [ "$mergeable" != "MERGEABLE" ]; then
            error "PR #${pr_number} has merge conflicts"
            tip "Resolve conflicts and try again"
            return "$EXIT_VALIDATION_FAILED"
        fi

        success "PR #${pr_number} is ready to merge"

        # Merge PR
        info "Merging PR to main..."
        if gh pr merge "$pr_number" --merge --delete-branch --subject "Merge PR #${pr_number}: ${pr_title}"; then
            success "PR #${pr_number} merged successfully"
            MERGE_SUCCEEDED=true
        else
            error "Merge failed"
            return "$EXIT_GIT_ERROR"
        fi

        # Update local main
        info "Updating local main branch..."
        git checkout main >/dev/null 2>&1
        git pull origin main >/dev/null 2>&1
        success "Local main updated"

    elif [ "$provider" = "azure" ]; then
        # Azure DevOps workflow
        if [ "$force_current" = true ] || [ -z "$pr_input" ]; then
            branch_name=$(git branch --show-current)
            pr_id=$(az repos pr list --source-branch "$branch_name" --status active --query '[0].pullRequestId' -o tsv)

            if [ -z "$pr_id" ] || [ "$pr_id" = "null" ]; then
                error "No PR found for branch: ${branch_name}"
                return "$EXIT_VALIDATION_FAILED"
            fi
        elif [[ "$pr_input" =~ ^[0-9]+$ ]]; then
            pr_id="$pr_input"
            branch_name=$(az repos pr show --id "$pr_id" --query sourceRefName -o tsv | sed 's|refs/heads/||')
        elif [[ "$pr_input" =~ ^[A-Z][A-Z0-9-]*[0-9]+$ ]]; then
            TASK_ID="$pr_input"
            branch_name=$(git branch --list "feat/${TASK_ID}-*" --format='%(refname:short)' | head -1)

            if [ -z "$branch_name" ]; then
                error "No branch found for task: ${TASK_ID}"
                return "$EXIT_VALIDATION_FAILED"
            fi

            pr_id=$(az repos pr list --source-branch "$branch_name" --status active --query '[0].pullRequestId' -o tsv)
        fi

        success "PR #${pr_id}"
        success "Branch: ${branch_name}"

        # Verify PR status
        local pr_data
        pr_data=$(az repos pr show --id "$pr_id" --query '{status: status, mergeStatus: mergeStatus, title: title}' -o json)

        local status merge_status pr_title
        read -r status merge_status pr_title < <(echo "$pr_data" | jq -r '[.status, .mergeStatus, .title] | @tsv')

        if [ "$status" != "active" ]; then
            error "PR #${pr_id} is not active (status: ${status})"
            return "$EXIT_VALIDATION_FAILED"
        fi

        if [ "$merge_status" != "succeeded" ]; then
            error "PR #${pr_id} cannot be merged (merge status: ${merge_status})"
            return "$EXIT_VALIDATION_FAILED"
        fi

        # Manual merge for Azure
        info "Performing manual merge..."
        git fetch origin
        git checkout main
        git pull origin main

        if git merge --no-ff "origin/${branch_name}" -m "Merge PR #${pr_id}: ${pr_title}"; then
            git push origin main
            git push origin --delete "$branch_name" 2>/dev/null || warn "Could not delete remote branch"
            success "PR #${pr_id} merged successfully"
            MERGE_SUCCEEDED=true
        else
            error "Merge failed"
            return "$EXIT_GIT_ERROR"
        fi
    fi

    # Extract task ID if not already set
    if [ -z "$TASK_ID" ]; then
        TASK_ID=$(echo "$branch_name" | grep -oE '[A-Z][A-Z0-9-]*[0-9]+' | head -1 || echo "")
    fi

    # Delete local branch
    info "Deleting local branch..."
    if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
        git branch -D "$branch_name" >/dev/null 2>&1
        success "Local branch deleted"
    else
        info "Local branch not found (worktree only)"
    fi

    # Remove worktree
    info "Removing worktree..."
    local worktree_path
    worktree_path=$(git worktree list | grep "$branch_name" | awk '{print $1}' || echo "")

    if [ -n "$worktree_path" ]; then
        git worktree remove "$worktree_path" --force >/dev/null 2>&1
        success "Worktree removed: ${worktree_path}"
    else
        info "No worktree found"
    fi

    # Clean up lock
    if [ -n "$TASK_ID" ]; then
        if delete_lock "$TASK_ID" 2>/dev/null; then
            success "Lock file removed: ${TASK_ID}"
        else
            info "No lock file found for task ${TASK_ID}"
        fi
    fi

    log_task_event "merge" "${TASK_ID:-unknown}" "PR merged successfully" \
        "$(jq -n --arg branch "$branch_name" --arg pr "${pr_number:-${pr_id}}" '{branch: $branch, pr: $pr}')"

    if [ "${TASKDOCK_OUTPUT:-human}" = "json" ]; then
        json_success "PR merge complete" \
            "$(jq -n \
                --arg taskId "${TASK_ID}" \
                --arg branch "$branch_name" \
                --arg pr "${pr_number:-${pr_id}}" \
                '{taskId: $taskId, branch: $branch, pr: $pr}')"
    else
        echo ""
        success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        success "PR Merge Complete"
        success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "PR:     ${pr_number:-${pr_id}}"
        echo "Branch: ${branch_name}"
        [ -n "$TASK_ID" ] && echo "Task:   ${TASK_ID}"
        echo ""
        success "✅ PR merged to main"
        success "✅ Remote branch deleted"
        success "✅ Local branch deleted"
        success "✅ Worktree removed"
        success "✅ Lock file removed"
        echo ""
        tip "Main branch updated - ready for next task"
        tip "Run 'taskdock next' to start the next task"
    fi
}

cmd_manual() {
    local branch_name="${1:-}"

    if [ -z "$branch_name" ]; then
        branch_name=$(git branch --show-current)
        info "Using current branch: ${branch_name}"
    else
        info "Merging branch: ${branch_name}"
    fi

    # Safety check
    if [ "$branch_name" = "main" ] || [ "$branch_name" = "master" ]; then
        error "Cannot merge main/master into itself"
        return "$EXIT_INVALID_ARGS"
    fi

    # Find worktree
    local worktree_path=""
    while IFS= read -r line; do
        if [[ "$line" == worktree\ * ]]; then
            local current_wt="${line#worktree }"
        elif [[ "$line" == "branch refs/heads/${branch_name}" ]]; then
            worktree_path="$current_wt"
            break
        fi
    done < <(git worktree list --porcelain)

    [ -n "$worktree_path" ] && info "Worktree: ${worktree_path}"

    # Extract task ID
    TASK_ID=$(echo "$branch_name" | grep -oE '[A-Z][A-Z0-9-]*[0-9]+' | head -1 || echo "")
    [ -n "$TASK_ID" ] && info "Task ID: ${TASK_ID}"

    # Confirmation
    warn "This will:"
    echo "  1. Merge ${branch_name} → main (no PR)"
    echo "  2. Push to origin/main"
    echo "  3. Delete remote branch"
    echo "  4. Remove worktree (if exists)"
    echo "  5. Delete local branch"
    echo "  6. Clean up lock file"
    echo ""

    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warn "Merge cancelled"
        return 0
    fi

    # Update main
    info "Updating main branch..."
    git checkout main
    git pull origin main
    success "Main branch updated"

    # Merge
    info "Merging ${branch_name} into main..."
    if git merge --no-ff "$branch_name" -m "Merge ${branch_name}"; then
        success "Merge completed"
        MERGE_SUCCEEDED=true
    else
        error "Merge failed"
        return "$EXIT_GIT_ERROR"
    fi

    # Push
    info "Pushing to origin..."
    git push origin main
    success "Pushed to origin/main"

    # Delete remote branch
    if git push origin --delete "$branch_name" 2>/dev/null; then
        success "Remote branch deleted"
    else
        warn "Could not delete remote branch"
    fi

    # Delete local branch
    if git branch -d "$branch_name" 2>/dev/null; then
        success "Local branch deleted"
    else
        warn "Could not delete local branch"
    fi

    # Remove worktree
    if [ -n "$worktree_path" ] && [ -d "$worktree_path" ]; then
        git worktree remove "$worktree_path" --force 2>/dev/null || true
        success "Worktree removed"
    fi

    # Clean up lock
    if [ -n "$TASK_ID" ]; then
        delete_lock "$TASK_ID" 2>/dev/null && success "Lock removed" || true
    fi

    log_task_event "merge" "${TASK_ID:-unknown}" "Manual merge completed" \
        "$(jq -n --arg branch "$branch_name" '{branch: $branch, type: "manual"}')"

    if [ "${TASKDOCK_OUTPUT:-human}" = "json" ]; then
        json_success "Manual merge complete" \
            "$(jq -n --arg taskId "${TASK_ID}" --arg branch "$branch_name" '{taskId: $taskId, branch: $branch}')"
    else
        echo ""
        success "Manual merge complete!"
        tip "Run 'taskdock next' to start the next task"
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
        echo "Usage: taskdock merge <subcommand> [options]"
        echo ""
        echo "Subcommands:"
        echo "  pr [PR_NUM|TASK_ID|--current]  Merge PR and cleanup"
        echo "  manual [branch]                 Manual merge (no PR)"
        echo ""
        echo "Examples:"
        echo "  taskdock merge pr --current     # Merge current branch's PR"
        echo "  taskdock merge pr 123           # Merge PR #123"
        echo "  taskdock merge pr T0001         # Merge task T0001's PR"
        echo "  taskdock merge manual           # Manual merge current branch"
        return "$EXIT_INVALID_ARGS"
    fi

    shift

    case "$subcommand" in
        pr)
            cmd_pr "$@"
            ;;
        manual)
            cmd_manual "$@"
            ;;
        *)
            error "Unknown subcommand: ${subcommand}"
            tip "Run 'taskdock merge' to see available subcommands"
            return "$EXIT_INVALID_ARGS"
            ;;
    esac
}

main "$@"
