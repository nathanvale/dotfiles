#!/usr/bin/env bash
# TaskDock Doctor Command
# Check dependencies and system health

set -euo pipefail

TASKDOCK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"
source "$TASKDOCK_ROOT/lib/common.sh"
source "$TASKDOCK_ROOT/lib/ui.sh"
source "$TASKDOCK_ROOT/lib/config.sh"
source "$TASKDOCK_ROOT/lib/git.sh"
source "$TASKDOCK_ROOT/lib/locks.sh"

show_help() {
  print_help_header "taskdock doctor" "Check dependencies and system health"

  print_usage "taskdock doctor [options]"

  print_options "$(cat <<'EOF'
--json|Output in JSON format
--help, -h|Show this help
EOF
)"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# Collect diagnostics
CHECKS=()
WARNINGS=()
ERRORS=()

# Check: Bash version
BASH_MAJOR="${BASH_VERSINFO[0]}"
BASH_MINOR="${BASH_VERSINFO[1]}"
BASH_VERSION="${BASH_MAJOR}.${BASH_MINOR}"

if [[ "$BASH_MAJOR" -ge 4 ]]; then
  CHECKS+=("bash:$BASH_VERSION")
elif [[ "$BASH_MAJOR" -eq 3 ]] && [[ "$BASH_MINOR" -ge 2 ]]; then
  WARNINGS+=("bash:$BASH_VERSION (upgrade to 4.0+ recommended)")
else
  ERRORS+=("bash:$BASH_VERSION (unsupported, requires 3.2+)")
fi

# Check: Git
if command_exists git; then
  GIT_VERSION=$(git --version | awk '{print $3}')
  CHECKS+=("git:$GIT_VERSION")
else
  ERRORS+=("git:missing")
fi

# Check: jq
if command_exists jq; then
  JQ_VERSION=$(jq --version | sed 's/jq-//')
  CHECKS+=("jq:$JQ_VERSION")
else
  ERRORS+=("jq:missing")
fi

# Check: yq (optional)
if command_exists yq; then
  YQ_VERSION=$(yq --version 2>&1 | head -n1 | awk '{print $NF}')
  CHECKS+=("yq:$YQ_VERSION")
else
  WARNINGS+=("yq:missing (optional, for YAML config support)")
fi

# Check: flock (optional, we use mkdir-based locking as fallback)
if command_exists flock; then
  FLOCK_VERSION=$(flock --version 2>&1 | head -n1 | awk '{print $NF}' || echo "unknown")
  CHECKS+=("flock:$FLOCK_VERSION")
else
  CHECKS+=("flock:not available (using mkdir-based locking)")
fi

# Check: gh CLI (optional, for GitHub operations)
if command_exists gh; then
  GH_VERSION=$(gh --version 2>&1 | head -n1 | awk '{print $3}')
  CHECKS+=("gh:$GH_VERSION")
else
  WARNINGS+=("gh:missing (optional, for GitHub PR operations)")
fi

# Check: az CLI (optional, for Azure DevOps)
if command_exists az; then
  AZ_VERSION=$(az --version 2>&1 | grep "^azure-cli" | awk '{print $2}')
  CHECKS+=("az:$AZ_VERSION")
else
  WARNINGS+=("az:missing (optional, for Azure DevOps operations)")
fi

# Check: In git repo
REPO_ROOT="$(get_repo_root)"
if [[ -n "$REPO_ROOT" ]]; then
  CHECKS+=("git-repo:$(get_repo_name)")

  # Check: Repo initialized
  if is_repo_primed; then
    CHECKS+=("taskdock-init:yes")

    # Check: Ticket prefix configured
    TICKET_PREFIX="$(taskdock_config "ticket_prefix")"
    if [[ -n "$TICKET_PREFIX" ]]; then
      CHECKS+=("ticket-prefix:$TICKET_PREFIX")
    else
      ERRORS+=("ticket-prefix:not-set")
    fi

    # Check: Stale locks
    LOCK_DIR="$(get_lock_dir)"
    if [[ -d "$LOCK_DIR" ]]; then
      LOCK_COUNT=$(find "$LOCK_DIR" -name "*.lock" 2>/dev/null | wc -l | tr -d ' ')
      if [[ "$LOCK_COUNT" -gt 0 ]]; then
        WARNINGS+=("locks:$LOCK_COUNT active")
      else
        CHECKS+=("locks:none")
      fi
    fi

    # Check: Working tree clean
    if is_working_tree_clean; then
      CHECKS+=("working-tree:clean")
    else
      WARNINGS+=("working-tree:dirty")
    fi

  else
    ERRORS+=("taskdock-init:no (run 'taskdock init')")
  fi
else
  WARNINGS+=("git-repo:not in a repository")
fi

# Check: pnpm (optional, for validation)
if command_exists pnpm; then
  PNPM_VERSION=$(pnpm --version)
  CHECKS+=("pnpm:$PNPM_VERSION")
else
  WARNINGS+=("pnpm:missing (optional, for package validation)")
fi

# Determine overall health
HEALTH_STATUS="healthy"
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  HEALTH_STATUS="unhealthy"
elif [[ ${#WARNINGS[@]} -gt 0 ]]; then
  HEALTH_STATUS="degraded"
fi

# Output results
if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
  jq -n \
    --arg status "$HEALTH_STATUS" \
    --argjson checks "$(printf '%s\n' "${CHECKS[@]}" | jq -R . | jq -s .)" \
    --argjson warnings "$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s .)" \
    --argjson errors "$(printf '%s\n' "${ERRORS[@]}" | jq -R . | jq -s .)" \
    '{
      status: $status,
      checks: $checks,
      warnings: $warnings,
      errors: $errors
    }'
else
  echo ""
  info "TaskDock Health Check"
  echo ""

  if [[ ${#CHECKS[@]} -gt 0 ]]; then
    echo "✓ Passed checks:"
    for check in "${CHECKS[@]}"; do
      echo "  • $check"
    done
    echo ""
  fi

  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "⚠ Warnings:"
    for warning in "${WARNINGS[@]}"; do
      echo "  • $warning"
    done
    echo ""
  fi

  if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo "✗ Errors:"
    for error in "${ERRORS[@]}"; do
      echo "  • $error"
    done
    echo ""
  fi

  case "$HEALTH_STATUS" in
    healthy)
      success "System is healthy"
      ;;
    degraded)
      warn "System has warnings but is functional"
      ;;
    unhealthy)
      error "System has critical errors"
      tip "Install missing dependencies or run 'taskdock init'"
      ;;
  esac
  echo ""
fi

# Exit with appropriate code
if [[ "$HEALTH_STATUS" == "unhealthy" ]]; then
  exit "$EXIT_DEPENDENCY_MISSING"
fi

exit 0
