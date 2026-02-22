#!/usr/bin/env bash
# sidequest-common.sh - Shared helpers for @side-quest/git CLI integration
#
# Configuration (all env vars, set in .bashrc/.zshrc or inline):
#   USE_SIDEQUEST=0|1       - Toggle CLI mode (default: 0 = native)
#   SIDEQUEST_GIT_CMD=...   - CLI command override (default: bunx @side-quest/git@0.2.0)
#   SIDEQUEST_LOG=~/.cache/sidequest-worktree.log  - Operation log path

# Environment variables
USE_SIDEQUEST="${USE_SIDEQUEST:-0}"
SIDEQUEST_GIT_CMD="${SIDEQUEST_GIT_CMD:-bunx @side-quest/git@0.2.0}"
SIDEQUEST_LOG="${SIDEQUEST_LOG:-$HOME/.cache/sidequest-worktree.log}"

# Track if preflight banner has been shown
_SIDEQUEST_PREFLIGHT_DONE=0

# sidequest_preflight - Validate environment and mode
#
# Validates USE_SIDEQUEST value, checks dependencies, performs runtime version check,
# and prints mode banner once per session.
sidequest_preflight() {
	local original_mode="$USE_SIDEQUEST"

	# Validate USE_SIDEQUEST is 0 or 1
	if [[ "$USE_SIDEQUEST" != "0" && "$USE_SIDEQUEST" != "1" ]]; then
		echo "[worktree] invalid USE_SIDEQUEST='$USE_SIDEQUEST', defaulting to 0" >&2
		USE_SIDEQUEST=0
		export USE_SIDEQUEST
	fi

	# If already run, skip
	if [[ "$_SIDEQUEST_PREFLIGHT_DONE" == "1" ]]; then
		return 0
	fi

	# Native mode - no checks needed
	if [[ "$USE_SIDEQUEST" == "0" ]]; then
		echo "[worktree] mode: native" >&2
		_SIDEQUEST_PREFLIGHT_DONE=1
		return 0
	fi

	# CLI mode checks
	if ! command -v bunx >/dev/null 2>&1; then
		echo "[worktree] bunx not found, disabling CLI mode" >&2
		USE_SIDEQUEST=0
		export USE_SIDEQUEST
		echo "[worktree] mode: native" >&2
		_SIDEQUEST_PREFLIGHT_DONE=1
		return 0
	fi

	if ! command -v jq >/dev/null 2>&1; then
		echo "[worktree] ERROR: jq required for CLI mode but not found" >&2
		exit 1
	fi

	# Runtime check with timeout (CLI has no --version flag, so use worktree list)
	if ! timeout 10 $SIDEQUEST_GIT_CMD worktree list --json >/dev/null 2>&1; then
		echo "[worktree] CLI version check failed, using native mode" >&2
		USE_SIDEQUEST=0
		export USE_SIDEQUEST
		echo "[worktree] mode: native" >&2
		_SIDEQUEST_PREFLIGHT_DONE=1
		return 0
	fi

	# Success - CLI mode active
	echo "[worktree] mode: cli" >&2
	_SIDEQUEST_PREFLIGHT_DONE=1
}

# sidequest_log - Append operation log entry
#
# Args:
#   $1 - mode (cli|native)
#   $2 - command (create|delete)
#   $3 - branch_or_path
#   $4 - exit_code
#   $5 - error_summary (optional)
sidequest_log() {
	local mode="$1"
	local command="$2"
	local branch_or_path="$3"
	local exit_code="$4"
	local error_summary="${5:-}"

	local timestamp
	timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

	local log_dir
	log_dir=$(dirname "$SIDEQUEST_LOG")
	mkdir -p "$log_dir"

	local log_entry="$timestamp $mode $command $branch_or_path $exit_code"
	if [[ -n "$error_summary" ]]; then
		log_entry="$log_entry $error_summary"
	fi

	echo "$log_entry" >>"$SIDEQUEST_LOG"
}

# sidequest_error - Format and persist error messages
#
# Args:
#   $1 - operation (e.g., "create worktree")
#   $2 - error_message
#   $3 - command_attempted
#   $4 - recovery_command (optional)
sidequest_error() {
	local operation="$1"
	local error_message="$2"
	local command_attempted="$3"
	local recovery_command="${4:-}"

	local error_output
	error_output="[worktree] $operation failed: $error_message"
	error_output="$error_output
[worktree] command: $command_attempted"

	if [[ -n "$recovery_command" ]]; then
		error_output="$error_output
[worktree] recovery: $recovery_command"
	fi

	error_output="$error_output
[worktree] log: $SIDEQUEST_LOG"

	# Output to stderr
	echo "$error_output" >&2

	# Persist to last error file
	local error_file="$HOME/.cache/sidequest-worktree-last-error.txt"
	mkdir -p "$(dirname "$error_file")"
	echo "$error_output" >"$error_file"
}

# sidequest_verify_node - Check node availability and version
#
# Returns:
#   0 if node is available
#   1 if node is not found
sidequest_verify_node() {
	if ! command -v node >/dev/null 2>&1; then
		echo "[worktree] node not found" >&2
		return 1
	fi

	local node_version
	node_version=$(node -v 2>&1)
	echo "[worktree] node version: $node_version" >&2
	return 0
}

# sidequest_recover_create - Cleanup failed worktree creation
#
# Args:
#   $1 - worktree_path
#
# Attempts targeted removal, falls back to prune, verifies cleanup.
sidequest_recover_create() {
	local worktree_path="$1"

	echo "[worktree] recovery: attempting targeted removal" >&2
	if git worktree remove --force "$worktree_path" 2>&1 | tee -a "$SIDEQUEST_LOG" >&2; then
		echo "[worktree] recovery: targeted removal succeeded" >&2
	else
		echo "[worktree] recovery: targeted removal failed, trying prune" >&2
		if git worktree prune --expire now 2>&1 | tee -a "$SIDEQUEST_LOG" >&2; then
			echo "[worktree] recovery: prune succeeded" >&2
		else
			echo "[worktree] recovery: prune failed" >&2
		fi
	fi

	# Verify cleanup
	if git worktree list --porcelain | grep -q "worktree $worktree_path"; then
		echo "[worktree] recovery: verification failed - worktree still exists" >&2
		return 1
	else
		echo "[worktree] recovery: verification passed - worktree removed" >&2
		return 0
	fi
}

# sidequest_check_worktree_exists - Check if worktree already exists
#
# Args:
#   $1 - worktree_path
#
# Returns:
#   0 if worktree exists
#   1 if worktree does not exist
sidequest_check_worktree_exists() {
	local worktree_path="$1"
	local normalized_path

	# Normalize path using realpath if it exists, otherwise use as-is
	if command -v realpath >/dev/null 2>&1; then
		normalized_path=$(realpath "$worktree_path" 2>/dev/null || echo "$worktree_path")
	else
		normalized_path="$worktree_path"
	fi

	if git worktree list --porcelain | grep -q "^worktree $normalized_path$"; then
		return 0
	else
		return 1
	fi
}
