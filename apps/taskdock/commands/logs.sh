#!/usr/bin/env bash
# TaskDock Logs Command
# View TaskDock telemetry logs

set -euo pipefail

TASKDOCK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"
source "$TASKDOCK_ROOT/lib/common.sh"
source "$TASKDOCK_ROOT/lib/ui.sh"
source "$TASKDOCK_ROOT/lib/logging.sh"
source "$TASKDOCK_ROOT/lib/git.sh"

show_help() {
  print_help_header "taskdock logs" "View TaskDock telemetry logs"

  print_usage "taskdock logs [options]"

  print_options "$(cat <<'EOF'
--tail, -n <N>|Show last N log entries (default: 50)
--follow, -f|Follow log output (like tail -f)
--command <cmd>|Filter by command name
--correlation-id <id>|Filter by correlation ID
--repo|Show repo-level logs (default: user-level)
--all|Show both user and repo logs
--json|Output in JSON format
--help, -h|Show this help
EOF
)"

  print_examples "$(cat <<'EOF'
  taskdock logs --tail 20
  taskdock logs --follow
  taskdock logs --command next
  taskdock logs --correlation-id TD-20251119-123456-abc123
  taskdock logs --repo --json
EOF
)"
}

# Parse arguments
TAIL_LINES=50
FOLLOW=false
FILTER_COMMAND=""
FILTER_CORRELATION=""
SCOPE="user"  # user, repo, or all

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tail|-n)
      TAIL_LINES="$2"
      shift 2
      ;;
    --follow|-f)
      FOLLOW=true
      shift
      ;;
    --command)
      FILTER_COMMAND="$2"
      shift 2
      ;;
    --correlation-id)
      FILTER_CORRELATION="$2"
      shift 2
      ;;
    --repo)
      SCOPE="repo"
      shift
      ;;
    --all)
      SCOPE="all"
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# Determine log files to read
LOG_FILES=()

if [[ "$SCOPE" == "user" ]] || [[ "$SCOPE" == "all" ]]; then
  USER_LOG="$TASKDOCK_LOG_DIR/taskdock.log"
  if [[ -f "$USER_LOG" ]]; then
    LOG_FILES+=("$USER_LOG")
  fi
fi

if [[ "$SCOPE" == "repo" ]] || [[ "$SCOPE" == "all" ]]; then
  REPO_LOG_DIR="$(get_repo_log_dir)"
  if [[ -n "$REPO_LOG_DIR" ]] && [[ -f "$REPO_LOG_DIR/taskdock.log" ]]; then
    LOG_FILES+=("$REPO_LOG_DIR/taskdock.log")
  fi
fi

if [[ ${#LOG_FILES[@]} -eq 0 ]]; then
  warn "No log files found"
  tip "Run TaskDock commands to generate logs"
  exit 0
fi

# Build jq filter
JQ_FILTER="."

if [[ -n "$FILTER_COMMAND" ]]; then
  JQ_FILTER="$JQ_FILTER | select(.command == \"$FILTER_COMMAND\")"
fi

if [[ -n "$FILTER_CORRELATION" ]]; then
  JQ_FILTER="$JQ_FILTER | select(.correlationId == \"$FILTER_CORRELATION\")"
fi

# Output logs
if [[ "$FOLLOW" == "true" ]]; then
  # Follow mode
  if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
    tail -f "${LOG_FILES[@]}" | grep --line-buffered '^{"ts":.*}$' | jq -c "$JQ_FILTER"
  else
    tail -f "${LOG_FILES[@]}" | grep --line-buffered '^{"ts":.*}$' | while read -r line; do
      echo "$line" | jq -r '"[\(.ts)] [\(.level | ascii_upcase)] [\(.command)] \(.message) | \(.correlationId)"'
    done
  fi
else
  # Tail mode
  if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
    cat "${LOG_FILES[@]}" | grep '^{"ts":.*}$' | tail -n "$TAIL_LINES" | jq -c "$JQ_FILTER"
  else
    info "TaskDock Logs (last $TAIL_LINES entries)"
    echo ""
    cat "${LOG_FILES[@]}" | grep '^{"ts":.*}$' | tail -n "$TAIL_LINES" | while read -r line; do
      level=$(echo "$line" | jq -r '.level')

      color=""
      case "$level" in
        error) color="$COLOR_RED" ;;
        warn) color="$COLOR_YELLOW" ;;
        info) color="$COLOR_CYAN" ;;
      esac

      if [[ -n "$color" ]]; then
        echo -e "${color}$(echo "$line" | jq -r '"[\(.ts)] [\(.level | ascii_upcase)] [\(.command)] \(.message)"')${COLOR_RESET}"
      else
        echo "$line" | jq -r '"[\(.ts)] [\(.level | ascii_upcase)] [\(.command)] \(.message)"'
      fi
    done
    echo ""

    if [[ ${#LOG_FILES[@]} -gt 0 ]]; then
      echo "Log files:"
      for log_file in "${LOG_FILES[@]}"; do
        echo "  • $log_file"
      done
      echo ""
    fi
  fi
fi

exit 0
