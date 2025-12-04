#!/usr/bin/env zsh
# ----------------------------------------------------------------------------
# SCRIPT_NAME - Brief description of what this script does
# ----------------------------------------------------------------------------
# Usage:
#   script_name command     # Description of command
#   script_name help        # Show this help
# ----------------------------------------------------------------------------

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly VERSION="1.0.0"

# Add your configuration variables here
# readonly CONFIG_DIR="${HOME}/.config/${SCRIPT_NAME}"

# ============================================================================
# Colors (disabled when piped, NO_COLOR set, or dumb terminal)
# ============================================================================

if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
  readonly GREEN=$'\033[0;32m'
  readonly BLUE=$'\033[0;34m'
  readonly YELLOW=$'\033[0;33m'
  readonly RED=$'\033[0;31m'
  readonly GRAY=$'\033[0;90m'
  readonly BOLD=$'\033[1m'
  readonly RESET=$'\033[0m'
else
  readonly GREEN='' BLUE='' YELLOW='' RED='' GRAY='' BOLD='' RESET=''
fi

# ============================================================================
# Logging Functions
# ============================================================================

#######################################
# Print an error message to stderr
# Arguments:
#   $1 - Error message
# Outputs:
#   Writes error message to stderr
#######################################
err() {
  echo "${RED}Error:${RESET} $*" >&2
}

#######################################
# Print a warning message to stderr
# Arguments:
#   $1 - Warning message
# Outputs:
#   Writes warning message to stderr
#######################################
warn() {
  echo "${YELLOW}Warning:${RESET} $*" >&2
}

#######################################
# Print an info message
# Arguments:
#   $1 - Info message
# Outputs:
#   Writes info message to stdout
#######################################
info() {
  echo "${BLUE}Info:${RESET} $*"
}

#######################################
# Print a success message
# Arguments:
#   $1 - Success message
# Outputs:
#   Writes success message to stdout
#######################################
success() {
  echo "${GREEN}✓${RESET} $*"
}

#######################################
# Print a section header
# Arguments:
#   $1 - Header text
# Outputs:
#   Writes formatted header to stdout
#######################################
print_header() {
  echo "${BOLD}${BLUE}$1${RESET}"
  echo "${GRAY}────────────────────────────────────────${RESET}"
}

# ============================================================================
# Helper Functions
# ============================================================================

#######################################
# Check if a command exists
# Arguments:
#   $1 - Command name to check
# Returns:
#   0 if command exists, 1 otherwise
#######################################
command_exists() {
  command -v "$1" &>/dev/null
}

#######################################
# Require a command to exist or exit
# Arguments:
#   $1 - Command name to check
# Outputs:
#   Error message if command not found
# Returns:
#   Exits with 1 if command not found
#######################################
require_command() {
  if ! command_exists "$1"; then
    err "Required command not found: $1"
    exit 1
  fi
}

# ============================================================================
# Commands
# ============================================================================

#######################################
# Example command implementation
# Globals:
#   None
# Arguments:
#   $@ - Command arguments
# Outputs:
#   Writes result to stdout
# Returns:
#   0 on success, non-zero on error
#######################################
cmd_example() {
  local arg="${1:-default}"
  print_header "Example Command"
  echo "Running with argument: ${arg}"
  success "Example completed"
}

#######################################
# Display help information
# Globals:
#   SCRIPT_NAME
#   VERSION
# Arguments:
#   None
# Outputs:
#   Writes help text to stdout
#######################################
cmd_help() {
  cat <<EOF
${BOLD}${BLUE}${SCRIPT_NAME}${RESET} v${VERSION} - Brief description

${BOLD}USAGE:${RESET}
  ${SCRIPT_NAME} <command> [options]

${BOLD}COMMANDS:${RESET}
  ${GREEN}example [arg]${RESET}   Run the example command
  ${GREEN}help${RESET}            Show this help message
  ${GREEN}version${RESET}         Show version information

${BOLD}OPTIONS:${RESET}
  ${GREEN}-h, --help${RESET}      Show this help message
  ${GREEN}-v, --version${RESET}   Show version information

${BOLD}EXAMPLES:${RESET}
  ${SCRIPT_NAME} example          # Run with defaults
  ${SCRIPT_NAME} example foo      # Run with argument

${BOLD}ENVIRONMENT:${RESET}
  ${GRAY}NO_COLOR${RESET}         Disable colored output
EOF
}

#######################################
# Display version information
# Globals:
#   SCRIPT_NAME
#   VERSION
# Arguments:
#   None
# Outputs:
#   Writes version to stdout
#######################################
cmd_version() {
  echo "${SCRIPT_NAME} v${VERSION}"
}

# ============================================================================
# Main Command Router
# ============================================================================

#######################################
# Main entry point - routes to subcommands
# Globals:
#   None
# Arguments:
#   $@ - Command line arguments
# Returns:
#   Exit code from subcommand
#######################################
main() {
  # Handle global flags first
  case "${1-}" in
    -h|--help)
      cmd_help
      return 0
      ;;
    -v|--version)
      cmd_version
      return 0
      ;;
  esac

  # Route to subcommand (default to help)
  local cmd="${1:-help}"
  [[ $# -gt 0 ]] && shift

  case "${cmd}" in
    example)  cmd_example "$@" ;;
    help)     cmd_help ;;
    version)  cmd_version ;;
    *)
      err "Unknown command '${cmd}'"
      echo "Run '${SCRIPT_NAME} help' for usage information" >&2
      return 1
      ;;
  esac
}

# Only run main if not being sourced
if [[ "${zsh_eval_context[-1]}" != "file" ]]; then
  main "$@"
fi
