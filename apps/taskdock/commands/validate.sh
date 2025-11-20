#!/usr/bin/env bash
# TaskDock validate - Run validation checks on worktree
# Supports both monorepo and single-repo projects

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/git.sh"

# ============================================================================
# HELPERS
# ============================================================================

script_exists() {
    local script_name="$1"
    local package_json="$2"

    if [ -f "$package_json" ]; then
        grep -q "\"$script_name\"" "$package_json"
        return $?
    fi
    return 1
}

detect_package_manager() {
    local worktree_path="$1"

    if [ -f "${worktree_path}/pnpm-lock.yaml" ]; then
        echo "pnpm"
    elif [ -f "${worktree_path}/package-lock.json" ]; then
        echo "npm"
    elif [ -f "${worktree_path}/yarn.lock" ]; then
        echo "yarn"
    else
        echo ""
    fi
}

is_monorepo() {
    local worktree_path="$1"

    if [ -f "${worktree_path}/pnpm-workspace.yaml" ] || \
       [ -f "${worktree_path}/lerna.json" ] || \
       [ -d "${worktree_path}/packages" ]; then
        return 0
    fi
    return 1
}

auto_detect_package() {
    local worktree_path="$1"

    # Try to find task file in worktree
    local task_file
    task_file=$(find "${worktree_path}" \
        -path "*/docs/tasks/T*.md" -o \
        -path "*/docs/tasks/MPCU-*.md" 2>/dev/null | head -1 || true)

    if [ -n "$task_file" ]; then
        # Extract package dir from task file path
        local package_dir
        package_dir=$(dirname "$(dirname "$(dirname "$task_file")")")
        basename "$package_dir"
    else
        echo ""
    fi
}

# ============================================================================
# MAIN
# ============================================================================

show_help() {
    cat <<EOF
TaskDock v${TASKDOCK_VERSION} - taskdock validate

Run validation checks on worktree (format, typecheck, lint, tests)

Usage:
  taskdock validate [worktree-path] [package-name]

Arguments:
  worktree-path    Path to worktree (default: current directory)
  package-name     Package name for monorepo (auto-detected if not specified)

Options:
  --help, -h       Show this help

Examples:
  taskdock validate
  taskdock validate .worktrees/MPCU-0001
  taskdock validate .worktrees/MPCU-0001 @myorg/api
EOF
}

main() {
    # Check for help flag first
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi

    local worktree_path="${1:-}"
    local package_name="${2:-}"

    # Parse flags
    shift || true
    [ -n "${1:-}" ] && shift || true

    if [ -z "$worktree_path" ]; then
        # Default to current worktree
        worktree_path="$(get_repo_root)"
    fi

    if [ ! -d "$worktree_path" ]; then
        error "Worktree not found: ${worktree_path}"
        return "$EXIT_VALIDATION_FAILED"
    fi

    info "Validating worktree: ${worktree_path}"

    # Detect project structure
    local is_mono=false
    if is_monorepo "$worktree_path"; then
        is_mono=true
        info "Detected: Monorepo"
    else
        info "Detected: Single repo"
    fi

    # Detect package manager
    local pkg_mgr
    pkg_mgr=$(detect_package_manager "$worktree_path")

    if [ -z "$pkg_mgr" ]; then
        error "No lock file found (pnpm-lock.yaml, package-lock.json, yarn.lock)"
        return "$EXIT_VALIDATION_FAILED"
    fi

    info "Package manager: ${pkg_mgr}"

    # Auto-detect package if needed
    if [ "$is_mono" = true ] && [ -z "$package_name" ]; then
        package_name=$(auto_detect_package "$worktree_path")
        if [ -n "$package_name" ]; then
            info "Auto-detected package: ${package_name}"
        fi
    fi

    # Get validation config
    local run_format run_typecheck run_lint run_tests
    run_format=$(taskdock_config validation.run_format 2>/dev/null || echo "true")
    run_typecheck=$(taskdock_config validation.run_typecheck 2>/dev/null || echo "true")
    run_lint=$(taskdock_config validation.run_lint 2>/dev/null || echo "true")
    run_tests=$(taskdock_config validation.run_tests 2>/dev/null || echo "true")

    # Build command prefix
    local cmd_prefix
    local package_json

    if [ "$is_mono" = true ] && [ -n "$package_name" ]; then
        cd "$worktree_path"
        cmd_prefix="${pkg_mgr} --filter ${package_name}"

        # Find package.json for specific package
        package_json=$(find "${worktree_path}/apps" "${worktree_path}/packages" \
            -type f -name "package.json" -path "*/${package_name}/package.json" 2>/dev/null | head -1)
    else
        # Single repo
        if [ "$pkg_mgr" = "pnpm" ]; then
            cmd_prefix="${pkg_mgr} --prefix ${worktree_path}"
        elif [ "$pkg_mgr" = "npm" ]; then
            cmd_prefix="${pkg_mgr} --prefix ${worktree_path} run"
        elif [ "$pkg_mgr" = "yarn" ]; then
            cmd_prefix="${pkg_mgr} --cwd ${worktree_path}"
        fi

        package_json="${worktree_path}/package.json"
    fi

    # Track results
    local failed_checks=0
    local skipped_checks=0
    local passed_checks=0
    local checks_run=()

    echo ""

    # 1. Format check
    if [ "$run_format" = "true" ]; then
        info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        info "1️⃣  Running format check..."
        info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        if ! script_exists "format" "$package_json"; then
            warn "Format script not found - skipping"
            skipped_checks=$((skipped_checks + 1))
            checks_run+=('{"name":"format","result":"skipped","reason":"script not found"}')
        elif $cmd_prefix format 2>&1; then
            success "Format check passed"
            passed_checks=$((passed_checks + 1))
            checks_run+=('{"name":"format","result":"passed"}')
        else
            error "Format check failed"
            failed_checks=$((failed_checks + 1))
            checks_run+=('{"name":"format","result":"failed"}')
        fi
        echo ""
    fi

    # 2. Typecheck
    if [ "$run_typecheck" = "true" ]; then
        info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        info "2️⃣  Running typecheck..."
        info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        if ! script_exists "typecheck" "$package_json"; then
            error "Typecheck script not found (REQUIRED)"
            failed_checks=$((failed_checks + 1))
            checks_run+=('{"name":"typecheck","result":"failed","reason":"script not found"}')
        elif $cmd_prefix typecheck 2>&1 | head -100; then
            success "Typecheck passed"
            passed_checks=$((passed_checks + 1))
            checks_run+=('{"name":"typecheck","result":"passed"}')
        else
            local exit_code=$?
            if [ $exit_code -eq 137 ]; then
                warn "Typecheck killed (OOM - exit 137)"
                tip "Try checking specific files instead"
                failed_checks=$((failed_checks + 1))
                checks_run+=('{"name":"typecheck","result":"failed","reason":"OOM"}')
            else
                error "Typecheck failed"
                failed_checks=$((failed_checks + 1))
                checks_run+=('{"name":"typecheck","result":"failed"}')
            fi
        fi
        echo ""
    fi

    # 3. Lint
    if [ "$run_lint" = "true" ]; then
        info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        info "3️⃣  Running lint..."
        info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        if ! script_exists "lint" "$package_json"; then
            warn "Lint script not found - skipping"
            skipped_checks=$((skipped_checks + 1))
            checks_run+=('{"name":"lint","result":"skipped","reason":"script not found"}')
        elif $cmd_prefix lint 2>&1; then
            success "Lint passed"
            passed_checks=$((passed_checks + 1))
            checks_run+=('{"name":"lint","result":"passed"}')
        else
            error "Lint failed"
            failed_checks=$((failed_checks + 1))
            checks_run+=('{"name":"lint","result":"failed"}')
        fi
        echo ""
    fi

    # 4. Tests
    if [ "$run_tests" = "true" ]; then
        info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        info "4️⃣  Running tests..."
        info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        if ! script_exists "test" "$package_json"; then
            error "Test script not found (REQUIRED)"
            failed_checks=$((failed_checks + 1))
            checks_run+=('{"name":"test","result":"failed","reason":"script not found"}')
        elif $cmd_prefix test 2>&1; then
            success "Tests passed"
            passed_checks=$((passed_checks + 1))
            checks_run+=('{"name":"test","result":"passed"}')
        else
            error "Tests failed"
            failed_checks=$((failed_checks + 1))
            checks_run+=('{"name":"test","result":"failed"}')
        fi
        echo ""
    fi

    # Summary
    info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    info "📊 Validation Summary"
    info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo "Passed:  $(color_green "${passed_checks}")"
    echo "Failed:  $(color_red "${failed_checks}")"
    if [ $skipped_checks -gt 0 ]; then
        echo "Skipped: $(color_yellow "${skipped_checks}") (optional scripts not found)"
    fi
    echo ""

    # Build checks JSON array
    local checks_json="[$(IFS=,; echo "${checks_run[*]}")]"

    if [ $failed_checks -eq 0 ]; then
        log_task_event "validate" "$(basename "$worktree_path")" "Validation passed" "$checks_json"

        if [ "${TASKDOCK_OUTPUT:-human}" = "json" ]; then
            json_success "All validation checks passed" \
                "$(jq -n \
                    --argjson passed "$passed_checks" \
                    --argjson failed "$failed_checks" \
                    --argjson skipped "$skipped_checks" \
                    --argjson checks "$checks_json" \
                    '{passed: $passed, failed: $failed, skipped: $skipped, checks: $checks}')"
        else
            success "All validation checks passed"
        fi
        return 0
    else
        log_task_event "validate" "$(basename "$worktree_path")" "Validation failed" "$checks_json"

        if [ "${TASKDOCK_OUTPUT:-human}" = "json" ]; then
            json_error "Validation failed: ${failed_checks} check(s) failed" "$EXIT_VALIDATION_FAILED" \
                "$(jq -n \
                    --argjson passed "$passed_checks" \
                    --argjson failed "$failed_checks" \
                    --argjson skipped "$skipped_checks" \
                    --argjson checks "$checks_json" \
                    '{passed: $passed, failed: $failed, skipped: $skipped, checks: $checks}')"
        else
            error "Validation failed: ${failed_checks} check(s) failed"
            echo ""
            warn "Next steps:"
            echo "  1. Fix the issues"
            echo "  2. Re-run: taskdock validate"
            echo "  3. Repeat until all checks pass"
            echo ""
            error "⚠️  DO NOT mark task as COMPLETED until all checks pass"
        fi
        return "$EXIT_VALIDATION_FAILED"
    fi
}

main "$@"
