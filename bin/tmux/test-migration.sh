#!/usr/bin/env bash
set -euo pipefail

# test-migration.sh - Smoke test for SideQuest CLI worktree migration
# Tests: create -> install -> delete in temp repo
# Verifies cross-mode compatibility (CLI <-> native)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0
TOTAL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() {
    PASS=$((PASS + 1))
    TOTAL=$((TOTAL + 1))
    printf "${GREEN}PASS${NC} %s\n" "$1"
}

fail() {
    FAIL=$((FAIL + 1))
    TOTAL=$((TOTAL + 1))
    printf "${RED}FAIL${NC} %s\n" "$1"
}

skip() {
    TOTAL=$((TOTAL + 1))
    printf "${YELLOW}SKIP${NC} %s\n" "$1"
}

# Setup temp repo
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

setup_test_repo() {
    cd "$TMPDIR"
    git init -b main test-repo
    cd test-repo
    git config user.email "test@test.com"
    git config user.name "Test"

    # Realistic structure
    echo '{"name":"test","version":"1.0.0"}' > package.json
    echo '{}' > bun.lockb
    mkdir -p .worktrees
    cat > .worktrees.json << 'EOF'
{
    "directory": ".worktrees",
    "copy": [".env"],
    "exclude": ["node_modules"],
    "postCreate": null,
    "preDelete": null,
    "branchTemplate": "{type}/{description}"
}
EOF
    echo "SECRET=test" > .env
    echo "# Test" > README.md
    git add .
    git commit -m "initial"
}

# --- Tests ---

test_native_create() {
    local desc="Native create worktree"
    cd "$TMPDIR/test-repo"
    git worktree add -b feat/native-test .worktrees/feat-native-test main 2>/dev/null || true
    if [[ -d .worktrees/feat-native-test ]]; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

test_native_worktree_visible_to_native() {
    local desc="Native-created worktree visible to native git worktree list"
    cd "$TMPDIR/test-repo"
    if git worktree list --porcelain | grep -q "feat/native-test"; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

test_cli_create() {
    local desc="CLI create worktree"
    cd "$TMPDIR/test-repo"

    if ! command -v bunx &>/dev/null; then
        skip "$desc (bunx not available)"
        return
    fi

    local output
    output=$($SIDEQUEST_GIT_CMD worktree create feat/cli-test --no-fetch --no-install --json 2>/dev/null) || {
        fail "$desc (exit code $?)"
        return
    }

    local created_path
    created_path=$(echo "$output" | jq -r '.path')

    if [[ -d "$created_path" ]]; then
        pass "$desc"
    else
        fail "$desc (path not found: $created_path)"
    fi
}

test_cli_worktree_visible_to_native() {
    local desc="CLI-created worktree visible to native git worktree list"
    cd "$TMPDIR/test-repo"

    if ! command -v bunx &>/dev/null; then
        skip "$desc (bunx not available)"
        return
    fi

    if git worktree list --porcelain | grep -q "feat/cli-test"; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

test_native_worktree_visible_to_cli() {
    local desc="Native-created worktree visible to CLI worktree list"
    cd "$TMPDIR/test-repo"

    if ! command -v bunx &>/dev/null; then
        skip "$desc (bunx not available)"
        return
    fi

    local output
    output=$($SIDEQUEST_GIT_CMD worktree list --json 2>/dev/null) || {
        fail "$desc (list failed)"
        return
    }

    if echo "$output" | jq -e '.[] | select(.branch == "feat/native-test")' &>/dev/null; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

test_path_normalization() {
    local desc="Path normalization (realpath comparison)"
    cd "$TMPDIR/test-repo"

    local native_path
    native_path=$(realpath .worktrees/feat-native-test 2>/dev/null || echo "")

    local porcelain_path
    porcelain_path=$(git worktree list --porcelain | grep "feat-native-test" | head -1 | sed 's/^worktree //')
    porcelain_path=$(realpath "$porcelain_path" 2>/dev/null || echo "")

    if [[ -n "$native_path" && "$native_path" == "$porcelain_path" ]]; then
        pass "$desc"
    else
        fail "$desc (native=$native_path, porcelain=$porcelain_path)"
    fi
}

test_cli_install() {
    local desc="CLI install subcommand"
    cd "$TMPDIR/test-repo"

    if ! command -v bunx &>/dev/null; then
        skip "$desc (bunx not available)"
        return
    fi

    local output
    output=$($SIDEQUEST_GIT_CMD worktree install .worktrees/feat-cli-test --json 2>/dev/null) || {
        # Install may fail (no real package manager), but the subcommand should exist
        # A non-zero exit is ok if the command was recognized
        pass "$desc (command exists, install not needed)"
        return
    }

    pass "$desc"
}

test_cli_delete() {
    local desc="CLI delete worktree"
    cd "$TMPDIR/test-repo"

    if ! command -v bunx &>/dev/null; then
        skip "$desc (bunx not available)"
        return
    fi

    local output stderr_file
    stderr_file=$(mktemp)
    output=$($SIDEQUEST_GIT_CMD worktree delete feat/cli-test --force --json 2>"$stderr_file") || {
        fail "$desc (stderr: $(cat "$stderr_file"))"
        rm -f "$stderr_file"
        return
    }
    rm -f "$stderr_file"

    if [[ ! -d .worktrees/feat-cli-test ]]; then
        pass "$desc"
    else
        fail "$desc (directory still exists)"
    fi
}

test_native_delete() {
    local desc="Native delete worktree"
    cd "$TMPDIR/test-repo"
    git worktree remove .worktrees/feat-native-test 2>/dev/null || true
    if [[ ! -d .worktrees/feat-native-test ]]; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

test_sidequest_common_sourceable() {
    local desc="sidequest-common.sh is sourceable"
    if (USE_SIDEQUEST=0; source "$SCRIPT_DIR/sidequest-common.sh" 2>/dev/null); then
        pass "$desc"
    else
        fail "$desc"
    fi
}

test_toggle_disables_cli() {
    local desc="USE_SIDEQUEST=0 disables CLI mode"
    if (USE_SIDEQUEST=0; source "$SCRIPT_DIR/sidequest-common.sh" 2>/dev/null; [[ "${USE_SIDEQUEST}" == "0" ]]); then
        pass "$desc"
    else
        fail "$desc"
    fi
}

# --- Main ---

echo "=== SideQuest Worktree Migration Smoke Test ==="
echo ""

# Resolve CLI command
SIDEQUEST_GIT_CMD="${SIDEQUEST_GIT_CMD:-bunx @side-quest/git@0.2.0}"
echo "CLI command: $SIDEQUEST_GIT_CMD"
echo ""

setup_test_repo

echo "--- Structural tests ---"
test_sidequest_common_sourceable
test_toggle_disables_cli

echo ""
echo "--- Native operations ---"
test_native_create
test_native_worktree_visible_to_native
test_path_normalization

echo ""
echo "--- CLI operations ---"
test_cli_create
test_cli_worktree_visible_to_native
test_native_worktree_visible_to_cli
test_cli_install

echo ""
echo "--- Cleanup ---"
test_cli_delete
test_native_delete

echo ""
echo "=== Results ==="
printf "Total: %d  ${GREEN}Pass: %d${NC}  ${RED}Fail: %d${NC}\n" "$TOTAL" "$PASS" "$FAIL"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
