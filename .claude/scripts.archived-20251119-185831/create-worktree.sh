#!/bin/bash
# Universal Git Worktree Creator for Task Orchestration
# Location: ~/.claude/scripts/create-worktree.sh
# Works in ANY git repository (single repo or monorepo)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
SKIP_INSTALL=false
TASK_ID=""
PACKAGE_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-install)
            SKIP_INSTALL=true
            shift
            ;;
        -*)
            echo -e "${RED}❌ ERROR: Unknown option: $1${NC}"
            exit 1
            ;;
        *)
            if [ -z "$TASK_ID" ]; then
                TASK_ID="$1"
            elif [ -z "$PACKAGE_PATH" ]; then
                PACKAGE_PATH="$1"
            fi
            shift
            ;;
    esac
done

# Validate required argument
if [ -z "$TASK_ID" ]; then
    echo -e "${RED}❌ ERROR: Task ID required${NC}"
    echo "Usage: $0 T0001 [package-path] [--no-install]"
    echo ""
    echo "Examples:"
    echo "  $0 T0001                    # Single repo or specify package manually"
    echo "  $0 T0001 apps/api           # Monorepo with specific package"
    echo "  $0 T0001 --no-install       # Skip dependency installation"
    exit 1
fi

# Read git config options (gtr-compatible)
WORKTREE_BASE=$(git config --get gtr.worktree.path 2>/dev/null || echo "./.worktrees")
TMUX_ENABLED=$(git config --bool --get gtr.tmux.enabled 2>/dev/null || echo "false")
TMUX_MODE=$(git config --get gtr.tmux.mode 2>/dev/null || echo "manual")
AUTO_INSTALL=$(git config --bool --get claude.worktree.autoInstall 2>/dev/null || echo "true")

# Override auto-install if --no-install flag was passed
if [ "$SKIP_INSTALL" = true ]; then
    AUTO_INSTALL="false"
fi

WORKTREE_PATH="${WORKTREE_BASE}/${TASK_ID}"

# Get centralized project lock directory (shared across all worktrees)
source ~/.claude/scripts/lib/get-project-lock-dir.sh
LOCK_DIR=$(get_project_lock_dir)
LOCK_FILE="${LOCK_DIR}/${TASK_ID}.lock"

if ! command -v jq >/dev/null 2>&1; then
    echo -e "${RED}❌ ERROR: jq is required for worktree creation${NC}"
    exit 1
fi

timestamp_utc() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

AGENT_ID="${CLAUDE_AGENT_ID:-${USER}-agent-$$}"
HOSTNAME_VALUE="$(hostname)"

echo -e "${BLUE}🔍 Detecting project structure...${NC}"

# ============================================================================
# STEP 1: Auto-detect project structure
# ============================================================================

# Detect if monorepo
IS_MONOREPO=false
if [ -d "apps" ] || [ -d "packages" ]; then
    IS_MONOREPO=true
    echo -e "${BLUE}📦 Monorepo detected${NC}"
else
    echo -e "${BLUE}📦 Single repo detected${NC}"
fi

# ============================================================================
# STEP 2: Find task file
# ============================================================================

echo -e "${BLUE}📋 Finding task file for ${TASK_ID}...${NC}"

if [ -n "$PACKAGE_PATH" ]; then
    # Package explicitly specified
    TASK_FILE_PATH=$(find "$PACKAGE_PATH" -path "*/docs/tasks/${TASK_ID}-*.md" -o -path "*/tasks/${TASK_ID}-*.md" | head -n 1)
elif [ "$IS_MONOREPO" = true ]; then
    # Monorepo: search all packages
    TASK_FILE_PATH=$(find . -path "*/docs/tasks/${TASK_ID}-*.md" -o -path "*/tasks/${TASK_ID}-*.md" | head -n 1)
else
    # Single repo: search common locations
    TASK_FILE_PATH=$(find . -maxdepth 3 -path "*/docs/tasks/${TASK_ID}-*.md" -o -path "*/tasks/${TASK_ID}-*.md" -o -path "*/.tasks/${TASK_ID}-*.md" | head -n 1)
fi

if [ -z "$TASK_FILE_PATH" ]; then
    echo -e "${RED}❌ ERROR: Task file not found for ${TASK_ID}${NC}"
    echo "Searched in:"
    echo "  - docs/tasks/"
    echo "  - tasks/"
    echo "  - .tasks/"
    if [ "$IS_MONOREPO" = true ]; then
        echo "  - apps/*/docs/tasks/"
        echo "  - packages/*/docs/tasks/"
    fi
    exit 1
fi

echo -e "${GREEN}✅ Found: ${TASK_FILE_PATH}${NC}"

# ============================================================================
# STEP 2.5: Check GitHub integration (optional)
# ============================================================================

# Extract GitHub issue URL from task file frontmatter (optional)
GITHUB_URL=$(grep '^github:' "$TASK_FILE_PATH" 2>/dev/null | sed 's/github: *//' | tr -d '[:space:]' || echo "")
GITHUB_ISSUE_NUM=""

if [ -n "$GITHUB_URL" ]; then
    # Extract issue number from URL
    GITHUB_ISSUE_NUM=$(echo "$GITHUB_URL" | grep -oE '[0-9]+$' || echo "")

    if [ -n "$GITHUB_ISSUE_NUM" ]; then
        echo -e "${BLUE}🔗 GitHub integration detected: Issue #${GITHUB_ISSUE_NUM}${NC}"

        # Check if gh CLI is available
        if command -v gh &> /dev/null; then
            # Check current assignee
            CURRENT_ASSIGNEE=$(gh issue view "$GITHUB_ISSUE_NUM" --json assignees -q '.assignees[0].login' 2>/dev/null || echo "")

            if [ -n "$CURRENT_ASSIGNEE" ] && [ "$CURRENT_ASSIGNEE" != "$USER" ]; then
                echo -e "${RED}❌ ERROR: Task ${TASK_ID} is assigned to @${CURRENT_ASSIGNEE} on GitHub${NC}"
                echo "This task is being worked on by another team member."
                echo "Choose a different task or coordinate with @${CURRENT_ASSIGNEE}."
                exit 1
            elif [ -n "$CURRENT_ASSIGNEE" ] && [ "$CURRENT_ASSIGNEE" = "$USER" ]; then
                echo -e "${GREEN}✅ Already assigned to you on GitHub${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  GitHub CLI (gh) not installed - skipping GitHub assignment check${NC}"
            echo "Install with: brew install gh"
        fi
    fi
fi

# Extract task title for branch name
TASK_TITLE=$(grep "^# " "$TASK_FILE_PATH" | head -n 1 | sed 's/^# //' | sed 's/^P[0-3]: //' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
BRANCH_NAME="feat/${TASK_ID}-${TASK_TITLE}"

echo -e "${BLUE}🌿 Branch: ${BRANCH_NAME}${NC}"

# ============================================================================
# STEP 3: Verify and update lock (should already exist from select-and-lock-task.sh)
# ============================================================================

# Function to check if process is running
is_process_running() {
    local pid=$1
    if ps -p "$pid" > /dev/null 2>&1; then
        return 0  # Running
    else
        return 1  # Not running
    fi
}

ensure_lock_file() {
    mkdir -p "$LOCK_DIR"
    if [ -f "$LOCK_FILE" ]; then
        return
    fi

    local now
    now=$(timestamp_utc)

    jq -n \
        --arg taskId "$TASK_ID" \
        --arg agentId "$AGENT_ID" \
        --arg hostname "$HOSTNAME_VALUE" \
        --arg lockedAt "$now" \
        --arg heartbeatAt "$now" \
        --arg status "LOCKED" \
        --argjson pid "$$" \
        '{
            taskId: $taskId,
            agentId: $agentId,
            hostname: $hostname,
            lockedAt: $lockedAt,
            heartbeatAt: $heartbeatAt,
            status: $status,
            pid: $pid
        }' > "$LOCK_FILE"

    echo -e "${GREEN}🔒 Lock created: ${LOCK_FILE}${NC}"
}

refresh_lock_metadata() {
    ~/.claude/scripts/update-lock-heartbeat.sh \
        --status "IN_PROGRESS" \
        --branch "$BRANCH_NAME" \
        --worktree "$WORKTREE_PATH" \
        --started-at "$(timestamp_utc)" \
        --task-file "$TASK_FILE_PATH" \
        --agent "$AGENT_ID" \
        --pid "$$" \
        --hostname "$HOSTNAME_VALUE" \
        --quiet \
        "$TASK_ID" >/dev/null 2>&1 || true
}

pulse_lock() {
    ~/.claude/scripts/update-lock-heartbeat.sh --quiet "$TASK_ID" >/dev/null 2>&1 || true
}

if [ -f "$LOCK_FILE" ]; then
    echo -e "${GREEN}✓ Lock file exists (created by select-and-lock-task.sh)${NC}"

    # Extract PID from lock file
    LOCK_PID=$(jq -r '.pid // empty' "$LOCK_FILE" 2>/dev/null || echo "")

    # Verify the lock is from an active process (or parent process in our session)
    if [ -n "$LOCK_PID" ] && ! is_process_running "$LOCK_PID"; then
        echo -e "${YELLOW}⚠️  Lock has stale PID - will update with current process${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  WARNING: No lock file found - this task may not have been selected via select-and-lock-task.sh${NC}"
    echo -e "${YELLOW}Creating lock now (manual worktree creation mode)${NC}"
    ensure_lock_file
fi

# Update lock with worktree details and heartbeat
refresh_lock_metadata

# ============================================================================
# STEP 4: Check git status (must be clean before creating worktree)
# ============================================================================

echo -e "${BLUE}🔍 Checking git status...${NC}"

git update-index --really-refresh > /dev/null 2>&1 || true

if ! git diff-index --quiet HEAD 2>/dev/null; then
    echo -e "${RED}❌ ERROR: Working directory is not clean${NC}"
    echo ""
    git status --short
    echo ""
    echo "Please commit or stash your changes before creating a worktree."
    exit 1
fi

# Check for untracked files (warning only - surfaces to user for decision)
if [ -n "$(git status --porcelain --untracked-files=normal | grep '^??')" ]; then
    echo -e "${YELLOW}⚠️  Warning: Untracked files exist${NC}"
    git status --short | grep '^??'
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo -e "${GREEN}✅ Working directory is clean${NC}"

# ============================================================================
# STEP 5: Check for existing worktree (crash recovery)
# ============================================================================

if git worktree list | grep -q "$WORKTREE_PATH"; then
    echo -e "${GREEN}📂 Worktree exists - resuming work in ${TASK_ID}${NC}"

    # Verify branch is correct
    EXISTING_BRANCH=$(git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

    if [ "$EXISTING_BRANCH" != "${BRANCH_NAME#refs/heads/}" ]; then
        echo -e "${RED}❌ ERROR: Worktree exists but on wrong branch${NC}"
        echo "Expected: ${BRANCH_NAME}"
        echo "Actual: $EXISTING_BRANCH"
        exit 1
    fi

    # Lock already updated at script start (Step 3)

    # Check what work was already done
    echo ""
    echo -e "${BLUE}📊 Crash recovery - checking existing work:${NC}"

    COMMIT_COUNT=$(git -C "$WORKTREE_PATH" rev-list --count main..HEAD 2>/dev/null || echo "0")
    echo "Commits on branch: $COMMIT_COUNT"

    if [ "$COMMIT_COUNT" -gt 0 ]; then
        echo ""
        echo "Recent commits:"
        git -C "$WORKTREE_PATH" log --oneline main..HEAD | head -n 5
        echo ""
        echo "Modified files:"
        git -C "$WORKTREE_PATH" diff --name-only main...HEAD
    fi

    echo ""
    echo -e "${GREEN}✅ Worktree ready for resume: ${WORKTREE_PATH}${NC}"
    exit 0
fi

# ============================================================================
# STEP 6: Create new worktree
# ============================================================================

echo -e "${BLUE}🚀 Creating new worktree for ${TASK_ID}...${NC}"

mkdir -p "$WORKTREE_BASE"

if ! git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" main 2>&1; then
    echo -e "${RED}❌ ERROR: Failed to create worktree${NC}"
    echo ""
    echo "This could mean:"
    echo "1. Branch ${BRANCH_NAME} already exists"
    echo "2. Branch is checked out in another worktree"
    exit 1
fi

echo -e "${GREEN}✅ Worktree created: ${WORKTREE_PATH}${NC}"

pulse_lock

# ============================================================================
# STEP 7: Setup worktree environment
# ============================================================================

echo -e "${BLUE}📦 Setting up worktree environment...${NC}"

# Get absolute path to worktree for all subsequent operations
WORKTREE_ABS_PATH=$(cd "$WORKTREE_PATH" && pwd)

# ============================================================================
# Copy .env files (handles monorepo and single-repo structures)
# ============================================================================

echo "Checking for .env files..."

# Get absolute path to main repo root (works from worktrees too)
MAIN_REPO_ROOT=$(git rev-parse --show-superproject-working-tree 2>/dev/null)
if [ -z "$MAIN_REPO_ROOT" ]; then
    MAIN_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
fi
if [ -z "$MAIN_REPO_ROOT" ]; then
    echo "⚠️  Warning: Could not determine git root directory"
    ENV_COPIED=false
else
    ENV_COPIED=false

    # Simple approach: recursively find all .env* files and mirror structure to worktree
    echo "🔍 Searching for .env files in main repo..."

    while IFS= read -r -d '' env_file; do
        # Get relative path from main repo root
        relative_path="${env_file#$MAIN_REPO_ROOT/}"

        # Target path in worktree (mirror exact location)
        target_file="$WORKTREE_ABS_PATH/$relative_path"
        target_dir=$(dirname "$target_file")

        # Create target directory and copy file
        mkdir -p "$target_dir"
        cp "$env_file" "$target_file"
        echo "✓ Copied $relative_path"
        ENV_COPIED=true
    done < <(find "$MAIN_REPO_ROOT" -maxdepth 3 -type f -name ".env*" ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/.worktrees/*" -print0 2>/dev/null)
fi

if [ "$ENV_COPIED" = false ]; then
    echo "⚠️  No .env files found - package installation may fail"
fi

# Detect package manager (check in worktree using absolute path)
if [ -f "$WORKTREE_ABS_PATH/pnpm-lock.yaml" ]; then
    PKG_MGR="pnpm"
elif [ -f "$WORKTREE_ABS_PATH/yarn.lock" ]; then
    PKG_MGR="yarn"
elif [ -f "$WORKTREE_ABS_PATH/bun.lockb" ]; then
    PKG_MGR="bun"
elif [ -f "$WORKTREE_ABS_PATH/package-lock.json" ]; then
    PKG_MGR="npm"
else
    PKG_MGR="npm"  # Default
fi

echo "✓ Detected package manager: $PKG_MGR"

# Install dependencies (using absolute paths, no cd required)
if [ "$AUTO_INSTALL" = "true" ] && [ -f "$WORKTREE_ABS_PATH/package.json" ]; then
    echo "Installing dependencies (this may take a moment)..."

    INSTALL_SUCCESS=false

    if [ "$IS_MONOREPO" = true ] && [ "$PKG_MGR" = "pnpm" ]; then
        # Monorepo with pnpm: extract actual package name from package.json
        PACKAGE_DIR=$(dirname "$TASK_FILE_PATH" | sed 's|/docs/tasks$||')
        PACKAGE_JSON_PATH="$REPO_ROOT/$PACKAGE_DIR/package.json"

        if [ -f "$PACKAGE_JSON_PATH" ]; then
            # Extract "name" field from package.json
            PACKAGE_NAME=$(grep -m1 '"name"' "$PACKAGE_JSON_PATH" | sed 's/.*"name": *"\([^"]*\)".*/\1/')

            if [ -n "$PACKAGE_NAME" ]; then
                # Run from REPO ROOT (where pnpm-workspace.yaml is)
                echo "  Running: pnpm install --filter $PACKAGE_NAME (from repo root)"
                if (cd "$REPO_ROOT" && $PKG_MGR install --filter "$PACKAGE_NAME" 2>&1 | grep -v "deprecated"); then
                    INSTALL_SUCCESS=true
                fi
            else
                echo -e "${YELLOW}  Could not extract package name from package.json, trying fallback...${NC}"
                if (cd "$WORKTREE_ABS_PATH" && $PKG_MGR install 2>&1 | grep -v "deprecated"); then
                    INSTALL_SUCCESS=true
                fi
            fi
        else
            # No package.json in expected location, fallback
            if (cd "$WORKTREE_ABS_PATH" && $PKG_MGR install 2>&1 | grep -v "deprecated"); then
                INSTALL_SUCCESS=true
            fi
        fi
    else
        # Non-monorepo or non-pnpm: run install from worktree
        if (cd "$WORKTREE_ABS_PATH" && $PKG_MGR install 2>&1 | grep -v "deprecated"); then
            INSTALL_SUCCESS=true
        fi
    fi

    if [ "$INSTALL_SUCCESS" = true ]; then
        echo "✓ Dependencies installed"
    else
        echo -e "${YELLOW}⚠️  Package installation failed - worktree created but may need manual setup${NC}"
        echo -e "${YELLOW}   Try running from repo root: pnpm install --filter <package-name>${NC}"
    fi
elif [ "$AUTO_INSTALL" = "false" ] && [ -f "$WORKTREE_ABS_PATH/package.json" ]; then
    echo -e "${YELLOW}⏭️  Skipping dependency installation (disabled via config or --no-install flag)${NC}"
    echo -e "${YELLOW}   Run manually if needed: cd $WORKTREE_PATH && $PKG_MGR install${NC}"
fi

pulse_lock

# ============================================================================
# STEP 8: Update task status IN WORKTREE
# ============================================================================
# Note: Lock was already created/updated in Step 3

echo -e "${BLUE}📝 Updating task status in worktree...${NC}"

# Find task file in worktree (using absolute path)
WORKTREE_TASK_FILE=$(find "$WORKTREE_ABS_PATH" -name "${TASK_ID}-*.md" | head -n 1)

if [ -f "$WORKTREE_TASK_FILE" ]; then
    # Update status field
    if grep -q "^status:" "$WORKTREE_TASK_FILE"; then
        sed -i.bak "s/^status:.*$/status: IN_PROGRESS/" "$WORKTREE_TASK_FILE"
        rm -f "${WORKTREE_TASK_FILE}.bak"
    fi

    # Add started timestamp
    TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    if grep -q "^started:" "$WORKTREE_TASK_FILE"; then
        sed -i.bak "s/^started:.*$/started: ${TIMESTAMP}/" "$WORKTREE_TASK_FILE"
        rm -f "${WORKTREE_TASK_FILE}.bak"
    else
        # Insert after status field
        awk -v ts="started: $TIMESTAMP" '/^status:/ {print; print ts; next} 1' "$WORKTREE_TASK_FILE" > "$WORKTREE_TASK_FILE.tmp"
        mv "$WORKTREE_TASK_FILE.tmp" "$WORKTREE_TASK_FILE"
    fi

    # Add branch field
    if grep -q "^branch:" "$WORKTREE_TASK_FILE"; then
        sed -i.bak "s|^branch:.*$|branch: ${BRANCH_NAME}|" "$WORKTREE_TASK_FILE"
        rm -f "${WORKTREE_TASK_FILE}.bak"
    else
        awk -v br="branch: $BRANCH_NAME" '/^started:/ {print; print br; next} 1' "$WORKTREE_TASK_FILE" > "$WORKTREE_TASK_FILE.tmp"
        mv "$WORKTREE_TASK_FILE.tmp" "$WORKTREE_TASK_FILE"
    fi

    # Add worktree field
    if grep -q "^worktree:" "$WORKTREE_TASK_FILE"; then
        sed -i.bak "s|^worktree:.*$|worktree: ${WORKTREE_PATH}|" "$WORKTREE_TASK_FILE"
        rm -f "${WORKTREE_TASK_FILE}.bak"
    else
        awk -v wt="worktree: $WORKTREE_PATH" '/^branch:/ {print; print wt; next} 1' "$WORKTREE_TASK_FILE" > "$WORKTREE_TASK_FILE.tmp"
        mv "$WORKTREE_TASK_FILE.tmp" "$WORKTREE_TASK_FILE"
    fi

    # Commit the task status change to feature branch (using git -C to avoid cd)
    git -C "$WORKTREE_ABS_PATH" add "$WORKTREE_TASK_FILE"
    git -C "$WORKTREE_ABS_PATH" commit -m "chore(${TASK_ID}): start task

Task status: IN_PROGRESS
Branch: ${BRANCH_NAME}
Worktree: ${WORKTREE_PATH}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

    echo -e "${GREEN}✅ Task status updated in worktree and committed${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: Task file not found in worktree${NC}"
fi

pulse_lock

# ============================================================================
# STEP 9: Self-assign on GitHub (optional, if GitHub integration detected)
# ============================================================================

if [ -n "$GITHUB_ISSUE_NUM" ] && command -v gh &> /dev/null; then
    echo -e "${BLUE}📌 Assigning GitHub issue #${GITHUB_ISSUE_NUM} to @${USER}...${NC}"

    if gh issue edit "$GITHUB_ISSUE_NUM" --add-assignee @me 2>/dev/null; then
        echo -e "${GREEN}✅ Self-assigned on GitHub for team visibility${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not self-assign on GitHub (may lack permissions)${NC}"
        echo "   Task coordination will rely on local locks only."
    fi
fi

# ============================================================================
# STEP 10: Execute post-create hook (if configured)
# ============================================================================

# Read hook command from git config (GTR-compatible)
POST_CREATE_HOOK=$(git config --get claude.hook.postCreate 2>/dev/null || echo "")

if [ -n "$POST_CREATE_HOOK" ]; then
    echo -e "${BLUE}🪝 Running post-create hook...${NC}"

    # Export environment variables for hook script
    export WORKTREE_PATH
    export WORKTREE_ABS_PATH
    export TASK_ID

pulse_lock
    export BRANCH_NAME
    export TASK_FILE_PATH
    export PKG_MGR
    export IS_MONOREPO

    # Execute hook in worktree directory
    if (cd "$WORKTREE_ABS_PATH" && eval "$POST_CREATE_HOOK"); then
        echo -e "${GREEN}✅ Post-create hook completed successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Post-create hook failed (exit code: $?)${NC}"
        echo "   Hook command: $POST_CREATE_HOOK"
        echo "   Worktree is still usable, but custom setup may be incomplete."
    fi
fi

# ============================================================================
# Success!
# ============================================================================

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Worktree ready for ${TASK_ID}${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "📁 Worktree: ${WORKTREE_PATH}"
echo "🌿 Branch: ${BRANCH_NAME}"
echo "🔒 Lock: ${LOCK_FILE}"
echo "📋 Task file: ${TASK_FILE_PATH}"
echo ""
echo -e "${BLUE}Next: Spawn parallel-worker agent to execute task${NC}"
echo ""
