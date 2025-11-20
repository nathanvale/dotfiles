#!/usr/bin/env bash
# TaskDock Init Command
# Initialize TaskDock in a repository

set -euo pipefail

TASKDOCK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"
source "$TASKDOCK_ROOT/lib/common.sh"
source "$TASKDOCK_ROOT/lib/ui.sh"
source "$TASKDOCK_ROOT/lib/config.sh"
source "$TASKDOCK_ROOT/lib/logging.sh"
source "$TASKDOCK_ROOT/lib/git.sh"

show_help() {
  print_help_header "taskdock init" "Initialize TaskDock in current repository"

  print_usage "taskdock init [options]"

  print_options "$(cat <<'EOF'
--ticket-prefix <PREFIX>|Set ticket prefix (e.g., MPCU, PROJ)
--force|Reinitialize even if already primed
--json|Output in JSON format
--help, -h|Show this help
EOF
)"

  print_examples "$(cat <<'EOF'
  taskdock init --ticket-prefix MPCU
  taskdock init --force --ticket-prefix PROJ
EOF
)"
}

# Parse arguments
TICKET_PREFIX=""
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ticket-prefix)
      TICKET_PREFIX="$2"
      shift 2
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      exit "$EXIT_INVALID_ARGS"
      ;;
  esac
done

# Check if in a git repo
REPO_ROOT="$(get_repo_root)"
if [[ -z "$REPO_ROOT" ]]; then
  error "Not in a git repository"
  tip "Run this command from within a git repository"

  if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
    json_response "$(json_error "Not in a git repository" "$EXIT_GIT_ERROR" '["cd <git-repo>", "git init"]')"
  fi

  exit "$EXIT_GIT_ERROR"
fi

# Check if already primed
REPO_CONFIG="$REPO_ROOT/$TASKDOCK_REPO_DIR_NAME/$TASKDOCK_REPO_CONFIG_NAME"
if [[ -f "$REPO_CONFIG" ]] && [[ "$FORCE" != "true" ]]; then
  warn "Repository already initialized at: $REPO_CONFIG"
  tip "Use --force to reinitialize"

  if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
    json_response "$(json_success "Already initialized" "$(jq -n --arg path "$REPO_CONFIG" '{configPath: $path}')")"
  fi

  exit 0
fi

# Prompt for ticket prefix if not provided
if [[ -z "$TICKET_PREFIX" ]]; then
  if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]] || is_ci; then
    error "Ticket prefix required"
    tip "Use --ticket-prefix <PREFIX>"

    if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
      json_response "$(json_error "Ticket prefix required" "$EXIT_CONFIG_MISSING" '["taskdock init --ticket-prefix MPCU"]')"
    fi

    exit "$EXIT_CONFIG_MISSING"
  fi

  echo ""
  info "Initializing TaskDock in: $(get_repo_name)"
  echo ""
  read -rp "Enter ticket prefix (e.g., MPCU, PROJ): " TICKET_PREFIX

  if [[ -z "$TICKET_PREFIX" ]]; then
    error "Ticket prefix cannot be empty"
    exit "$EXIT_CONFIG_MISSING"
  fi
fi

  # Create .taskdock directory structure
  TASKDOCK_DIR="$REPO_ROOT/$TASKDOCK_REPO_DIR_NAME"
  mkdir -p "$TASKDOCK_DIR"

# Create config file
PRIMED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$REPO_CONFIG" <<EOF
# TaskDock Repository Configuration
# Generated on: $PRIMED_AT

# Required: Ticket prefix for this repository
ticket_prefix: "$TICKET_PREFIX"

# Task management
task_directory: "docs/tasks"
lock_max_age_minutes: 30

# Worktree settings
worktree_root: ".worktrees"
branch_prefix: "feat"

# Git settings
default_branch: "main"

# Validation (customize per repo)
run_format: true
run_typecheck: true
run_lint: true
run_tests: true

# Telemetry
telemetry_enabled: true
EOF

# Create .gitignore for .taskdock
cat > "$TASKDOCK_DIR/.gitignore" <<EOF
# TaskDock local files
logs/
*.log
EOF

# Create primed marker
echo "$PRIMED_AT" > "$TASKDOCK_DIR/primed"

# Log event
log_info "init" "Repository initialized" "" "$(jq -n --arg prefix "$TICKET_PREFIX" --arg path "$REPO_CONFIG" '{ticketPrefix: $prefix, configPath: $path}')"

# Output success
success "TaskDock initialized successfully!"
info "Config: $REPO_CONFIG"
info "Ticket prefix: $TICKET_PREFIX"
echo ""
tip "Next steps:"
echo "  1. Review and customize $REPO_CONFIG"
echo "  2. Run 'taskdock doctor' to check dependencies"
echo "  3. Run 'taskdock next' to start working on tasks"
echo ""

if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
  json_response "$(json_success "Repository initialized" "$(jq -n \
    --arg prefix "$TICKET_PREFIX" \
    --arg path "$REPO_CONFIG" \
    --arg repo "$(get_repo_name)" \
    '{ticketPrefix: $prefix, configPath: $path, repoName: $repo}')")"
fi

exit 0
