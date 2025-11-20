#!/bin/bash
# Update lock heartbeat and metadata fields

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq is required for update-lock-heartbeat.sh" >&2
    exit 1
fi

source ~/.claude/scripts/lib/get-project-lock-dir.sh

timestamp_utc() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [options] TASK_ID

Options:
  --status VALUE        Set lock status
  --branch VALUE        Set branch name
  --worktree PATH       Set worktree path
  --agent VALUE         Set agentId
  --started-at TS       Set startedAt timestamp
  --task-file PATH      Record task file path
  --pid PID             Update pid (numeric)
  --hostname VALUE      Update hostname
  --lock-file PATH      Operate on a specific lock file
  --skip-heartbeat      Do not change heartbeat timestamp
  --quiet               Suppress success output
  -h, --help            Show this help
EOF
}

TASK_ID=""
STATUS_VALUE=""
BRANCH_VALUE=""
WORKTREE_VALUE=""
AGENT_VALUE=""
STARTED_AT_VALUE=""
TASK_FILE_VALUE=""
LOCK_FILE_OVERRIDE=""
PID_VALUE=""
HOSTNAME_VALUE=""
SKIP_HEARTBEAT="false"
QUIET="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --status)
            if [ -z "${2:-}" ]; then
                echo "--status requires a value" >&2
                exit 1
            fi
            STATUS_VALUE="$2"
            shift 2 ;;
        --branch)
            if [ -z "${2:-}" ]; then
                echo "--branch requires a value" >&2
                exit 1
            fi
            BRANCH_VALUE="$2"
            shift 2 ;;
        --worktree)
            if [ -z "${2:-}" ]; then
                echo "--worktree requires a value" >&2
                exit 1
            fi
            WORKTREE_VALUE="$2"
            shift 2 ;;
        --agent)
            if [ -z "${2:-}" ]; then
                echo "--agent requires a value" >&2
                exit 1
            fi
            AGENT_VALUE="$2"
            shift 2 ;;
        --started-at)
            if [ -z "${2:-}" ]; then
                echo "--started-at requires a value" >&2
                exit 1
            fi
            STARTED_AT_VALUE="$2"
            shift 2 ;;
        --task-file)
            if [ -z "${2:-}" ]; then
                echo "--task-file requires a value" >&2
                exit 1
            fi
            TASK_FILE_VALUE="$2"
            shift 2 ;;
        --lock-file)
            if [ -z "${2:-}" ]; then
                echo "--lock-file requires a value" >&2
                exit 1
            fi
            LOCK_FILE_OVERRIDE="$2"
            shift 2 ;;
        --pid)
            if [ -z "${2:-}" ]; then
                echo "--pid requires a value" >&2
                exit 1
            fi
            PID_VALUE="$2"
            shift 2 ;;
        --hostname)
            if [ -z "${2:-}" ]; then
                echo "--hostname requires a value" >&2
                exit 1
            fi
            HOSTNAME_VALUE="$2"
            shift 2 ;;
        --skip-heartbeat)
            SKIP_HEARTBEAT="true"
            shift ;;
        --quiet)
            QUIET="true"
            shift ;;
        -h|--help)
            usage
            exit 0 ;;
        --)
            shift
            break ;;
        -*)
            echo "Unknown option: $1" >&2
            usage
            exit 1 ;;
        *)
            if [ -z "$TASK_ID" ]; then
                TASK_ID="$1"
                shift
            else
                echo "Unexpected argument: $1" >&2
                exit 1
            fi
            ;;
    esac
done

if [ -z "$LOCK_FILE_OVERRIDE" ] && [ -z "$TASK_ID" ]; then
    echo "TASK_ID or --lock-file is required" >&2
    exit 1
fi

LOCK_DIR=$(get_project_lock_dir)
LOCK_FILE="${LOCK_FILE_OVERRIDE:-${LOCK_DIR}/${TASK_ID}.lock}"

if [ ! -f "$LOCK_FILE" ]; then
    echo "Lock file not found: $LOCK_FILE" >&2
    exit 1
fi

TMP_FILE=$(mktemp "${LOCK_FILE}.XXXX")
NOW=$(timestamp_utc)

JQ_FILTER='(.|objects)'
JQ_ARGS=()

if [ "$SKIP_HEARTBEAT" != "true" ]; then
    JQ_ARGS+=(--arg heartbeatAt "$NOW")
    JQ_FILTER+=' | .heartbeatAt = $heartbeatAt | .updatedAt = $heartbeatAt'
fi

if [ -n "$STATUS_VALUE" ]; then
    JQ_ARGS+=(--arg status "$STATUS_VALUE")
    JQ_FILTER+=' | .status = $status'
fi

if [ -n "$BRANCH_VALUE" ]; then
    JQ_ARGS+=(--arg branch "$BRANCH_VALUE")
    JQ_FILTER+=' | .branch = $branch'
fi

if [ -n "$WORKTREE_VALUE" ]; then
    JQ_ARGS+=(--arg worktree "$WORKTREE_VALUE")
    JQ_FILTER+=' | .worktreePath = $worktree'
fi

if [ -n "$AGENT_VALUE" ]; then
    JQ_ARGS+=(--arg agent "$AGENT_VALUE")
    JQ_FILTER+=' | .agentId = $agent'
fi

if [ -n "$STARTED_AT_VALUE" ]; then
    JQ_ARGS+=(--arg startedAt "$STARTED_AT_VALUE")
    JQ_FILTER+=' | .startedAt = $startedAt'
fi

if [ -n "$TASK_FILE_VALUE" ]; then
    JQ_ARGS+=(--arg taskFile "$TASK_FILE_VALUE")
    JQ_FILTER+=' | .taskFile = $taskFile'
fi

if [ -n "$PID_VALUE" ]; then
    if [[ "$PID_VALUE" =~ ^[0-9]+$ ]]; then
        JQ_ARGS+=(--argjson pid "$PID_VALUE")
        JQ_FILTER+=' | .pid = $pid'
    else
        echo "Invalid PID: $PID_VALUE" >&2
        exit 1
    fi
fi

if [ -n "$HOSTNAME_VALUE" ]; then
    JQ_ARGS+=(--arg hostname "$HOSTNAME_VALUE")
    JQ_FILTER+=' | .hostname = $hostname'
fi

jq "${JQ_ARGS[@]}" "$JQ_FILTER" "$LOCK_FILE" > "$TMP_FILE"
mv "$TMP_FILE" "$LOCK_FILE"

if [ "$QUIET" != "true" ]; then
    echo "✅ Updated lock: $LOCK_FILE"
fi
```}```}  Comment: need newline at end. script ensures jq objects? However `(|objects)` fails when `jq` reading? we need ensure `. | objects` to ensure treat as object. Works? but if file empty? but we create earlier. ok. Need to ensure `jq` load `patch` when `'{}'` string? we use `--argjson patch` but patch variable currently storing string like `'{}'` but not JSON? It's textual `'{}'`. Works: e.g., `PATCH='{}'`, `jq --argjson patch '{}'`? but we pass variable with braces? we pass as `'{}'`. Should be fine? maybe argu? we pass like `--argjson patch '{}'` but we need actual content of $PATCH. But we pass `--argjson patch "$PATCH"`? we pass variable contains newline? our command `jq --arg ts ... --argjson patch "$PATCH" ...` but separation? we currently call `jq --arg ts ... --argjson patch "$PATCH" '...' ...` but we wrote `jq --arg ts "$TIMESTAMP" --argjson patch "$PATCH" '...' ...`? check script? there is `jq --arg ts` line? yes near bottom line after patch we wrote `jq --arg ts "$TIMESTAMP" --argjson patch "$PATCH" ' ... '`. but quoting cause `patch` argument with spaces? but `--argjson patch` expects JSON string; quoting ensures `patch` value inserted? example: `PATCH='{
