#!/usr/bin/env bash
# TaskDock Config Command
# View and manage configuration

set -euo pipefail

TASKDOCK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"
source "$TASKDOCK_ROOT/lib/common.sh"
source "$TASKDOCK_ROOT/lib/ui.sh"
source "$TASKDOCK_ROOT/lib/config.sh"
source "$TASKDOCK_ROOT/lib/git.sh"
source "$TASKDOCK_ROOT/lib/flock.sh"

# Internal: Update config implementation (called under flock protection)
_update_config_impl() {
  local repo_config="$1"
  local key="$2"
  local value="$3"

  if command_exists yq; then
    yq eval -i ".$key = \"$value\"" "$repo_config"
  else
    # Fallback: append or update manually
    if grep -q "^${key}:" "$repo_config"; then
      # Update existing key (macOS sed compatible)
      sed -i '' "s|^${key}:.*|${key}: \"$value\"|" "$repo_config"
    else
      # Append new key
      echo "${key}: \"$value\"" >> "$repo_config"
    fi
  fi
}

show_help() {
  print_help_header "taskdock config" "View and manage TaskDock configuration"

  print_usage "taskdock config <subcommand> [options]"

  cat << EOF
Subcommands:
  show              Show current configuration
  get <key>         Get a specific config value
  set <key> <value> Set a config value (repo-level)
  check             Validate configuration

Options:
  --json            Output in JSON format
  --help, -h        Show this help

Examples:
  taskdock config show
  taskdock config get ticket_prefix
  taskdock config set ticket_prefix MPCU
  taskdock config check --json
EOF
}

# Subcommand: show
cmd_show() {
  local merged_config
  merged_config="$(get_merged_config)"

  if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
    echo "$merged_config" | jq '.'
  else
    info "TaskDock Configuration"
    echo ""
    echo "$merged_config" | jq -r 'to_entries[] | "  \(.key): \(.value)"'
    echo ""

    local repo_config
    repo_config="$(get_repo_config)"
    if [[ -n "$repo_config" ]] && [[ -f "$repo_config" ]]; then
      echo "Config sources:"
      echo "  • Defaults: $TASKDOCK_DEFAULTS_FILE"
      [[ -f "$TASKDOCK_USER_CONFIG" ]] && echo "  • User: $TASKDOCK_USER_CONFIG"
      echo "  • Repo: $repo_config"
    else
      echo "Config sources:"
      echo "  • Defaults: $TASKDOCK_DEFAULTS_FILE"
      [[ -f "$TASKDOCK_USER_CONFIG" ]] && echo "  • User: $TASKDOCK_USER_CONFIG"
      echo "  • Repo: (not initialized)"
    fi
    echo ""
  fi
}

# Subcommand: get
cmd_get() {
  local key="$1"
  local value
  value="$(taskdock_config "$key")"

  if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
    jq -n --arg key "$key" --arg value "$value" '{key: $key, value: $value}'
  else
    if [[ -n "$value" ]]; then
      echo "$value"
    else
      error "Config key '$key' not found"
      exit "$EXIT_CONFIG_MISSING"
    fi
  fi
}

# Subcommand: set
cmd_set() {
  local key="$1"
  local value="$2"

  # Must be in a repo
  local repo_root
  repo_root="$(get_repo_root)"
  if [[ -z "$repo_root" ]]; then
    error "Not in a git repository"
    tip "Run this command from within a git repository"
    exit "$EXIT_GIT_ERROR"
  fi

  # Get or create repo config
  local repo_config="$repo_root/$TASKDOCK_REPO_DIR_NAME/$TASKDOCK_REPO_CONFIG_NAME"

  if [[ ! -f "$repo_config" ]]; then
    error "Repository not initialized"
    tip "Run 'taskdock init' first"
    exit "$EXIT_CONFIG_MISSING"
  fi

  # Update config using yq or simple append (protected by flock)
  with_repo_flock "config-write" _update_config_impl "$repo_config" "$key" "$value"

  local update_result=$?
  if [[ $update_result -ne 0 ]]; then
    error "Failed to update config"
    exit "$EXIT_CONFIG_MISSING"
  fi

  success "Config updated: $key = $value"

  if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
    jq -n --arg key "$key" --arg value "$value" --arg path "$repo_config" \
      '{key: $key, value: $value, configPath: $path}'
  fi
}

# Subcommand: check
cmd_check() {
  local required_keys=("ticket_prefix" "task_directory" "worktree_root")
  local missing
  missing=($(get_missing_config "${required_keys[@]}"))

  local warnings=()
  local status="ok"

  # Check if repo is initialized
  if ! is_repo_primed; then
    warnings+=("Repository not initialized")
    status="uninitialized"
  fi

  # Check missing required keys
  if [[ ${#missing[@]} -gt 0 ]]; then
    status="incomplete"
  fi

  if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
    local missing_json
    missing_json=$(printf '%s\n' "${missing[@]}" | jq -R . | jq -s . || echo "[]")
    local warnings_json
    warnings_json=$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s . || echo "[]")

    jq -n \
      --arg status "$status" \
      --argjson missing "$missing_json" \
      --argjson warnings "$warnings_json" \
      '{status: $status, missingKeys: $missing, warnings: $warnings}'
  else
    if [[ "$status" == "ok" ]]; then
      success "Configuration is complete"
    else
      if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required configuration:"
        for key in "${missing[@]}"; do
          echo "  • $key"
        done
        echo ""
        tip "Set missing values with: taskdock config set <key> <value>"
      fi

      if [[ ${#warnings[@]} -gt 0 ]]; then
        warn "Warnings:"
        for warning in "${warnings[@]}"; do
          echo "  • $warning"
        done
        echo ""
      fi
    fi
  fi

  [[ "$status" == "ok" ]] && exit 0 || exit "$EXIT_CONFIG_MISSING"
}

# Parse arguments
SUBCOMMAND="${1:-}"

if [[ -z "$SUBCOMMAND" ]] || [[ "$SUBCOMMAND" == "--help" ]] || [[ "$SUBCOMMAND" == "-h" ]]; then
  show_help
  exit 0
fi

shift || true

case "$SUBCOMMAND" in
  show)
    cmd_show "$@"
    ;;
  get)
    if [[ $# -lt 1 ]]; then
      error "Missing config key"
      tip "Usage: taskdock config get <key>"
      exit "$EXIT_INVALID_ARGS"
    fi
    cmd_get "$@"
    ;;
  set)
    if [[ $# -lt 2 ]]; then
      error "Missing arguments"
      tip "Usage: taskdock config set <key> <value>"
      exit "$EXIT_INVALID_ARGS"
    fi
    cmd_set "$@"
    ;;
  check)
    cmd_check "$@"
    ;;
  *)
    error "Unknown subcommand: $SUBCOMMAND"
    tip "Run 'taskdock config --help' to see available subcommands"
    exit "$EXIT_INVALID_ARGS"
    ;;
esac
