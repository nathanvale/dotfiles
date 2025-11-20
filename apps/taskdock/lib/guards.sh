#!/usr/bin/env bash
# TaskDock Guards Library
# Command execution guards and validations

# Source common library
# shellcheck source=./common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
# shellcheck source=./ui.sh
source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"
# shellcheck source=./config.sh
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
# shellcheck source=./git.sh
source "$(dirname "${BASH_SOURCE[0]}")/git.sh"

# Commands that don't require repo initialization
INIT_EXEMPT_COMMANDS=("init" "version" "doctor" "help" "--help" "-h" "--version" "-v")

# Check if command requires repo to be initialized
requires_repo_init() {
  local command="$1"

  for exempt in "${INIT_EXEMPT_COMMANDS[@]}"; do
    if [[ "$command" == "$exempt" ]]; then
      return 1
    fi
  done

  return 0
}

# Guard: ensure we're in a git repo
guard_git_repo() {
  local repo_root
  repo_root="$(get_repo_root)"

  if [[ -z "$repo_root" ]]; then
    error "Not in a git repository"
    tip "Run this command from within a git repository"
    echo ""

    if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
      json_response "$(json_error "Not in a git repository" "$EXIT_GIT_ERROR" '["cd <git-repo>", "git init"]')"
    fi

    exit "$EXIT_GIT_ERROR"
  fi
}

# Guard: ensure repo is initialized (primed)
guard_repo_primed() {
  local command="${1:-unknown}"

  # Skip check for exempt commands
  if ! requires_repo_init "$command"; then
    return 0
  fi

  # Check if we're in a repo first
  guard_git_repo

  # Check if primed
  if ! is_repo_primed; then
    local repo_name
    repo_name="$(get_repo_name)"

    error "Repository '$repo_name' not initialized"
    tip "Run 'taskdock init' to set up TaskDock in this repository"
    echo ""
    echo "Example:"
    echo "  taskdock init --ticket-prefix MPCU"
    echo ""

    if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
      json_response "$(json_error "Repository not initialized" "$EXIT_CONFIG_MISSING" \
        '["taskdock init --ticket-prefix <PREFIX>", "taskdock init --help"]')"
    fi

    exit "$EXIT_CONFIG_MISSING"
  fi

  # Check required config
  local missing
  missing=($(get_missing_config "ticket_prefix"))

  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing required configuration: ticket_prefix"
    tip "Set it with: taskdock config set ticket_prefix <PREFIX>"

    if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
      json_response "$(json_error "Missing ticket_prefix configuration" "$EXIT_CONFIG_MISSING" \
        '["taskdock config set ticket_prefix MPCU"]')"
    fi

    exit "$EXIT_CONFIG_MISSING"
  fi
}

# Guard: ensure working tree is clean
guard_clean_worktree() {
  if ! is_working_tree_clean; then
    error "Working tree has uncommitted changes"
    tip "Commit or stash your changes before proceeding"

    if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
      json_response "$(json_error "Working tree is dirty" "$EXIT_GIT_ERROR" \
        '["git status", "git stash", "git commit -am \"wip\""]')"
    fi

    exit "$EXIT_GIT_ERROR"
  fi
}
