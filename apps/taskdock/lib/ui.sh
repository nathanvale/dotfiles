#!/usr/bin/env bash
# TaskDock UI Library
# Human and machine-friendly output formatting

# Source common library
# shellcheck source=./common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Output mode: human or json (controlled by --json flag or TASKDOCK_OUTPUT env)
TASKDOCK_OUTPUT_MODE="${TASKDOCK_OUTPUT:-human}"

# Set output mode
set_output_mode() {
  TASKDOCK_OUTPUT_MODE="$1"
}

# Print colored message (human mode only)
print_color() {
  local color="$1"
  shift
  if [[ "$TASKDOCK_OUTPUT_MODE" == "human" ]] && ! is_ci; then
    echo -e "${color}$*${COLOR_RESET}"
  elif [[ "$TASKDOCK_OUTPUT_MODE" == "human" ]]; then
    echo "$*"
  fi
}

# Success message
success() {
  if [[ "$TASKDOCK_OUTPUT_MODE" == "human" ]]; then
    print_color "$COLOR_GREEN" "${SYMBOL_SUCCESS} $*"
  fi
}

# Error message
error() {
  if [[ "$TASKDOCK_OUTPUT_MODE" == "human" ]]; then
    print_color "$COLOR_RED" "${SYMBOL_ERROR} $*" >&2
  fi
}

# Info message
info() {
  if [[ "$TASKDOCK_OUTPUT_MODE" == "human" ]]; then
    print_color "$COLOR_BLUE" "${SYMBOL_INFO} $*"
  fi
}

# Warning message
warn() {
  if [[ "$TASKDOCK_OUTPUT_MODE" == "human" ]]; then
    print_color "$COLOR_YELLOW" "${SYMBOL_ERROR} $*"
  fi
}

# Tip message
tip() {
  if [[ "$TASKDOCK_OUTPUT_MODE" == "human" ]]; then
    print_color "$COLOR_CYAN" "${SYMBOL_TIP} tip: $*"
  fi
}

# Output JSON response
json_response() {
  if [[ "$TASKDOCK_OUTPUT_MODE" == "json" ]]; then
    echo "$1" | jq -c '.'
  fi
}

# Build success JSON
json_success() {
  local message="$1"
  shift
  local data="${1:-{}}"

  jq -n \
    --arg msg "$message" \
    --arg corr "${TASKDOCK_CORRELATION_ID:-}" \
    --argjson data "$data" \
    '{
      ok: true,
      message: $msg,
      correlationId: $corr,
      data: $data
    }'
}

# Build error JSON
json_error() {
  local message="$1"
  local exit_code="${2:-1}"
  shift 2
  local actions="${1:-[]}"

  jq -n \
    --arg msg "$message" \
    --arg corr "${TASKDOCK_CORRELATION_ID:-}" \
    --argjson code "$exit_code" \
    --argjson actions "$actions" \
    '{
      ok: false,
      error: $msg,
      correlationId: $corr,
      exitCode: $code,
      suggestedActions: $actions
    }'
}

# Unified output: prints human message and/or JSON
output() {
  local type="$1"  # success, error, info, warn
  local message="$2"
  local json_data="${3:-{}}"

  case "$type" in
    success)
      success "$message"
      json_response "$(json_success "$message" "$json_data")"
      ;;
    error)
      error "$message"
      local exit_code="${4:-1}"
      local actions="${5:-[]}"
      json_response "$(json_error "$message" "$exit_code" "$actions")"
      ;;
    info)
      info "$message"
      ;;
    warn)
      warn "$message"
      ;;
  esac
}

# Print command help header
print_help_header() {
  local command="$1"
  local description="$2"

  if [[ "$TASKDOCK_OUTPUT_MODE" == "human" ]]; then
    echo "TaskDock v${TASKDOCK_VERSION} - $command"
    echo ""
    echo "$description"
    echo ""
  fi
}

# Print usage section
print_usage() {
  if [[ "$TASKDOCK_OUTPUT_MODE" == "human" ]]; then
    echo "Usage:"
    echo "  $1"
    echo ""
  fi
}

# Print options section
print_options() {
  if [[ "$TASKDOCK_OUTPUT_MODE" == "human" ]]; then
    echo "Options:"
    while IFS='|' read -r flag desc; do
      printf "  %-20s %s\n" "$flag" "$desc"
    done <<< "$1"
    echo ""
  fi
}

# Print examples section
print_examples() {
  if [[ "$TASKDOCK_OUTPUT_MODE" == "human" ]]; then
    echo "Examples:"
    echo "$1"
    echo ""
  fi
}
