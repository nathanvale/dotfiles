#!/bin/bash
# Parse next task JSON and export variables
# Location: ~/.claude/scripts/parse-next-task.sh
# Usage:
#   source ~/.claude/scripts/parse-next-task.sh              # Export variables + display
#   ~/.claude/scripts/parse-next-task.sh --output-json       # Output JSON only (for agents)

# Check if --output-json flag is set
OUTPUT_JSON=false
if [ "$1" = "--output-json" ]; then
    OUTPUT_JSON=true
fi

# Clean up stale locks before selecting
CLEANUP_SCRIPT="$HOME/.claude/scripts/cleanup-stale-locks.sh"
if [ -x "$CLEANUP_SCRIPT" ]; then
    "$CLEANUP_SCRIPT" --simple --quiet >/dev/null 2>&1 || true
fi

# Run select-and-lock-task and capture JSON (atomically selects AND locks)
TASK_JSON=$(~/.claude/scripts/select-and-lock-task.sh --json)

if [ -z "$TASK_JSON" ] || [ "$TASK_JSON" = "{}" ]; then
    if [ "$OUTPUT_JSON" = true ]; then
        echo "{}"
    else
        echo "❌ No READY tasks available"
        export TASK_ID=""
        export TASK_FILE=""
        export PRIORITY=""
        export TASK_TITLE=""
    fi
    exit 1
fi

# Parse JSON fields
TASK_ID=$(echo "$TASK_JSON" | jq -r '.taskId // empty')
TASK_FILE=$(echo "$TASK_JSON" | jq -r '.filePath // empty')
PRIORITY=$(echo "$TASK_JSON" | jq -r '.priority // empty')
TASK_TITLE=$(echo "$TASK_JSON" | jq -r '.title // empty')

if [ -z "$TASK_ID" ]; then
    if [ "$OUTPUT_JSON" = true ]; then
        echo "{}"
    else
        echo "❌ Failed to parse task JSON"
    fi
    exit 1
fi

# Output mode: JSON only
if [ "$OUTPUT_JSON" = true ]; then
    echo "$TASK_JSON"
    exit 0
fi

# Output mode: Display + Export (for source)
export TASK_ID
export TASK_FILE
export PRIORITY
export TASK_TITLE

# Display task info
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Selected Task: $TASK_ID ($PRIORITY)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📄 Title: $TASK_TITLE"
echo "📁 File: $TASK_FILE"
echo ""
