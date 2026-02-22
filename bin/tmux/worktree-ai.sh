#!/bin/bash
# bin/tmux/worktree-ai.sh
# Create a git worktree and spawn a new tmux session with the standard template
#
# Usage: worktree-ai.sh [branch-name]
#   - With no args: shows fzf picker for existing worktrees/branches
#   - With branch name: creates new worktree or attaches to existing session
#
# Session naming: <repo>-wt-<branch> (e.g., dotfiles-wt-feat-auth)

# NOTE: set -e disabled to prevent silent failures from tmux commands
# set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

WORKTREE_DIR=".worktrees"
SESSION_FILE="${HOME}/.cache/tmux-worktree-session"

# Patterns to copy from main worktree to new worktrees (gitignored but needed for dev)
# Override with WORKTREE_COPY_PATTERNS environment variable (space-separated)
# Root-level patterns (files/dirs in repo root only)
DEFAULT_COPY_PATTERNS=".env .env.* .envrc .claude .kit .tool-versions .nvmrc .node-version .python-version PROJECT_INDEX.json"
COPY_PATTERNS="${WORKTREE_COPY_PATTERNS:-$DEFAULT_COPY_PATTERNS}"

# Recursive patterns - copied from anywhere in the tree, preserving directory structure
# Override with WORKTREE_COPY_RECURSIVE environment variable (space-separated)
DEFAULT_COPY_RECURSIVE="CLAUDE.md *.kit"
COPY_RECURSIVE="${WORKTREE_COPY_RECURSIVE:-$DEFAULT_COPY_RECURSIVE}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --- SideQuest CLI integration ---
COMMON="$(dirname "${BASH_SOURCE[0]}")/sidequest-common.sh"
if [[ -f "$COMMON" ]]; then
    source "$COMMON" || { USE_SIDEQUEST=0; echo "[worktree] sidequest-common.sh failed to source, falling back to native" >&2; }
else
    USE_SIDEQUEST=0
fi

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Clean up stale session file from previous runs
cleanup_session_file() {
    if [[ -f "$SESSION_FILE" ]]; then
        # Remove if file is older than 60 seconds (stale from crashed run)
        local file_age
        file_age=$(( $(date +%s) - $(stat -f %m "$SESSION_FILE" 2>/dev/null || echo 0) ))
        if [[ $file_age -gt 60 ]]; then
            rm -f "$SESSION_FILE"
        fi
    fi
}

info() { printf "${BLUE}%s${NC}\n" "$1"; }
success() { printf "${GREEN}%s${NC}\n" "$1"; }
warning() { printf "${YELLOW}%s${NC}\n" "$1"; }
error() { printf "${RED}%s${NC}\n" "$1" >&2; exit 1; }

# Check if we're in a git repo
check_git_repo() {
    if ! git rev-parse --git-dir &>/dev/null; then
        error "Not in a git repository"
    fi
}

# Get the root of the main worktree (not a linked worktree)
get_repo_root() {
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)

    if [[ "$git_common_dir" == ".git" ]]; then
        # We're in the main worktree
        pwd
    else
        # We're in a linked worktree, get the main repo path
        dirname "$git_common_dir"
    fi
}

# Check if a branch already has a worktree
branch_has_worktree() {
    local branch="$1"
    git worktree list --porcelain | grep -q "^branch refs/heads/$branch$"
}

# Get the worktree path for a branch (if it exists)
get_worktree_path_for_branch() {
    local branch="$1"
    local current_path=""

    # Use process substitution to avoid subshell variable scope issue
    while read -r line; do
        if [[ "$line" == worktree\ * ]]; then
            current_path="${line#worktree }"
        elif [[ "$line" == "branch refs/heads/$branch" ]]; then
            echo "$current_path"
            return 0
        fi
    done < <(git worktree list --porcelain)
}

# Directories to never copy (large, generated, or would cause issues)
COPY_EXCLUDE_DIRS=".worktrees node_modules .git dist build vendor __pycache__ .venv venv"

# Validate pattern - only allow safe characters (alphanumeric, dots, asterisks, underscores, hyphens)
is_valid_pattern() {
    local pattern="$1"
    [[ "$pattern" =~ ^[a-zA-Z0-9.*_-]+$ ]]
}

# Check if basename is in exclusion list
is_excluded() {
    local name="$1"
    local exclude
    for exclude in $COPY_EXCLUDE_DIRS; do
        [[ "$name" == "$exclude" ]] && return 0
    done
    return 1
}

# Copy untracked files from main worktree to new worktree
# Args: $1 = source (main worktree), $2 = destination (new worktree)
copy_untracked_files() {
    local src="$1"
    local dest="$2"
    local copied=0
    local failed=0

    # Validate directories exist before proceeding
    if [[ ! -d "$src" ]]; then
        warning "Source directory does not exist: $src" >&2
        return 1
    fi
    if [[ ! -d "$dest" ]]; then
        warning "Destination directory does not exist: $dest" >&2
        return 1
    fi

    # Normalize paths to handle symlinks consistently
    src=$(cd "$src" && pwd -P) || { warning "Cannot access source: $src" >&2; return 1; }
    dest=$(cd "$dest" && pwd -P) || { warning "Cannot access destination: $dest" >&2; return 1; }

    info "Copying untracked files..." >&2

    # Enable nullglob locally to handle non-matching patterns gracefully
    local old_nullglob
    old_nullglob=$(shopt -p nullglob 2>/dev/null || echo "shopt -u nullglob")
    shopt -s nullglob

    # === Root-level patterns (COPY_PATTERNS) ===
    local pattern
    for pattern in $COPY_PATTERNS; do
        # Validate pattern for safety
        if ! is_valid_pattern "$pattern"; then
            warning "  Skipping invalid pattern: $pattern" >&2
            continue
        fi

        # Handle glob patterns (e.g., .env.*)
        local matches=()
        # shellcheck disable=SC2206
        matches=("$src"/$pattern)

        local item
        for item in "${matches[@]}"; do
            local basename
            basename=$(basename -- "$item")

            # Skip excluded directories
            is_excluded "$basename" && continue

            local dest_item="$dest/$basename"

            # Skip if already exists in destination
            [[ -e "$dest_item" ]] && continue

            # Copy file or directory with error reporting
            # Note: suppress stdout/stderr from cp; we report our own messages
            if [[ -d "$item" ]]; then
                if cp -R -- "$item" "$dest_item" >/dev/null 2>&1; then
                    success "  ✓ $basename/" >&2
                    copied=$((copied + 1))
                else
                    warning "  ✗ $basename/ (copy failed)" >&2
                    failed=$((failed + 1))
                fi
            else
                if cp -- "$item" "$dest_item" >/dev/null 2>&1; then
                    success "  ✓ $basename" >&2
                    copied=$((copied + 1))
                else
                    warning "  ✗ $basename (copy failed)" >&2
                    failed=$((failed + 1))
                fi
            fi
        done
    done

    # Restore nullglob setting
    eval "$old_nullglob"

    # === Recursive patterns (COPY_RECURSIVE) - preserves directory structure ===
    for pattern in $COPY_RECURSIVE; do
        # Validate pattern for safety (prevents command injection)
        if ! is_valid_pattern "$pattern"; then
            warning "  Skipping invalid pattern: $pattern" >&2
            continue
        fi

        # Build find command as array (safe from injection)
        local find_cmd=(find "$src" -name "$pattern" -type f)
        local exclude
        for exclude in $COPY_EXCLUDE_DIRS; do
            find_cmd+=(-not -path "*/$exclude/*")
        done
        find_cmd+=(-print0)

        # Execute find and process results
        while IFS= read -r -d '' item; do
            # Get path relative to source
            local rel_path="${item#$src/}"

            # Safety check: ensure rel_path is actually relative (not absolute)
            if [[ "$rel_path" == /* ]]; then
                warning "  Skipping file outside source: $item" >&2
                continue
            fi

            local dest_item="$dest/$rel_path"
            local dest_dir
            dest_dir=$(dirname -- "$dest_item")

            # Skip if already exists in destination
            [[ -e "$dest_item" ]] && continue

            # Create parent directory if needed
            if ! mkdir -p -- "$dest_dir" 2>/dev/null; then
                warning "  ✗ $rel_path (mkdir failed)" >&2
                failed=$((failed + 1))
                continue
            fi

            # Copy file with error reporting
            # Note: suppress stdout/stderr from cp; we report our own messages
            if cp -- "$item" "$dest_item" >/dev/null 2>&1; then
                success "  ✓ $rel_path" >&2
                copied=$((copied + 1))
            else
                warning "  ✗ $rel_path (copy failed)" >&2
                failed=$((failed + 1))
            fi
        done < <("${find_cmd[@]}" 2>/dev/null)
    done

    # Summary
    if [[ $copied -eq 0 && $failed -eq 0 ]]; then
        info "  (no untracked files to copy)" >&2
    elif [[ $failed -gt 0 ]]; then
        warning "  Copied: $copied, Failed: $failed" >&2
        return 1
    fi
    return 0
}

# Detect package manager from lock files and configuration
# Returns: bun, yarn, pnpm, npm, or empty string if no JS project detected
# Priority: Lock files > packageManager field > default (npm)
detect_package_manager() {
    local dir="$1"

    # No package.json = not a JS project
    [[ ! -f "$dir/package.json" ]] && return

    # Collect detected lock files for conflict warning
    local lock_files=()
    local managers=()

    # Check each lock file type (use -e to follow symlinks)
    if [[ -e "$dir/bun.lockb" ]] || [[ -e "$dir/bun.lock" ]]; then
        lock_files+=("bun.lock*")
        managers+=("bun")
    fi
    if [[ -e "$dir/yarn.lock" ]]; then
        lock_files+=("yarn.lock")
        managers+=("yarn")
    fi
    if [[ -e "$dir/pnpm-lock.yaml" ]]; then
        lock_files+=("pnpm-lock.yaml")
        managers+=("pnpm")
    fi
    if [[ -e "$dir/package-lock.json" ]]; then
        lock_files+=("package-lock.json")
        managers+=("npm")
    fi

    # Warn on multiple lock files (common source of issues)
    if [[ ${#managers[@]} -gt 1 ]]; then
        warning "Multiple lock files detected: ${lock_files[*]}" >&2
        warning "Using '${managers[0]}' (priority: bun > yarn > pnpm > npm)" >&2
    fi

    # Return first detected lock file's manager
    if [[ ${#managers[@]} -gt 0 ]]; then
        echo "${managers[0]}"
        return
    fi

    # No lock file - check packageManager field (corepack standard)
    # Format: "packageManager": "yarn@3.6.0"
    local pm_field
    pm_field=$(sed -n 's/.*"packageManager"[[:space:]]*:[[:space:]]*"\([^@"]*\).*/\1/p' "$dir/package.json" 2>/dev/null | head -1)
    if [[ -n "$pm_field" ]]; then
        case "$pm_field" in
            bun|yarn|pnpm|npm) echo "$pm_field" ;;
            *) echo "npm" ;;  # Unknown, fallback
        esac
        return
    fi

    # Ultimate fallback
    echo "npm"
}

# Switch to correct Node version if .nvmrc or .node-version exists
# Args: $1 = worktree path
switch_node_version() {
    local worktree_path="$1"

    # Check for version files
    if [[ ! -f "$worktree_path/.nvmrc" ]] && [[ ! -f "$worktree_path/.node-version" ]]; then
        return 0
    fi

    # Try fnm first (faster), then nvm
    if command -v fnm &>/dev/null; then
        info "Switching Node version (fnm)..." >&2
        (cd "$worktree_path" && eval "$(fnm env --shell bash)" && fnm use --install-if-missing) >&2 2>/dev/null || true
    elif [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        info "Switching Node version (nvm)..." >&2
        # shellcheck source=/dev/null
        (cd "$worktree_path" && source "$HOME/.nvm/nvm.sh" && nvm use) >&2 2>/dev/null || true
    fi
}

# Run package manager install in worktree
# Args: $1 = worktree path
run_package_install() {
    local worktree_path="$1"
    local pkg_manager
    local timeout_seconds="${WORKTREE_INSTALL_TIMEOUT:-300}"

    pkg_manager=$(detect_package_manager "$worktree_path")

    if [[ -z "$pkg_manager" ]]; then
        return 0  # Not a JS project, skip silently
    fi

    # Verify package manager is installed
    if ! command -v "$pkg_manager" &>/dev/null; then
        warning "Package manager '$pkg_manager' not found (skipping install)" >&2
        warning "Install it or run the install command manually" >&2
        return 0  # Non-fatal
    fi

    # Switch Node version if needed (before install)
    switch_node_version "$worktree_path"

    # Build install command with non-interactive flags
    local install_cmd
    case "$pkg_manager" in
        npm)
            # Use npm ci for reproducible installs (requires package-lock.json)
            if [[ -f "$worktree_path/package-lock.json" ]]; then
                install_cmd="npm ci --no-audit --no-fund"
            else
                install_cmd="npm install --no-audit --no-fund"
            fi
            ;;
        yarn)
            install_cmd="yarn install --frozen-lockfile --non-interactive"
            ;;
        pnpm)
            install_cmd="pnpm install --frozen-lockfile"
            ;;
        bun)
            install_cmd="bun install --frozen-lockfile"
            ;;
        *)
            warning "Unknown package manager: $pkg_manager" >&2
            return 1
            ;;
    esac

    info "Installing dependencies with $pkg_manager..." >&2

    # Detect timeout command (gtimeout on macOS with coreutils)
    local timeout_cmd=""
    if command -v gtimeout &>/dev/null; then
        timeout_cmd="gtimeout $timeout_seconds"
    elif command -v timeout &>/dev/null; then
        timeout_cmd="timeout $timeout_seconds"
    fi

    # Run install in subshell with optional timeout
    # CI=true forces non-interactive mode for most tools
    # </dev/null prevents any stdin prompts
    local exit_code
    if [[ -n "$timeout_cmd" ]]; then
        (cd "$worktree_path" && CI=true $timeout_cmd $install_cmd </dev/null) >&2
        exit_code=$?
    else
        (cd "$worktree_path" && CI=true $install_cmd </dev/null) >&2
        exit_code=$?
    fi

    if [[ $exit_code -eq 0 ]]; then
        success "Dependencies installed" >&2
        return 0
    elif [[ $exit_code -eq 124 ]]; then
        warning "Package install timed out after ${timeout_seconds}s" >&2
        warning "Run '$pkg_manager install' manually" >&2
        return 1
    else
        warning "Package install failed (exit: $exit_code)" >&2
        warning "Run '$pkg_manager install' manually" >&2
        return 1
    fi
}

# Check if package install should run (node_modules missing or stale)
# Args: $1 = worktree path
# Returns: 0 if install needed, 1 if up-to-date
should_run_install() {
    local dir="$1"

    # Not a JS project
    [[ ! -f "$dir/package.json" ]] && return 1

    # No node_modules = definitely needs install
    [[ ! -d "$dir/node_modules" ]] && return 0

    # Check if any lock file is newer than node_modules
    local lockfile
    for lockfile in bun.lockb bun.lock yarn.lock pnpm-lock.yaml package-lock.json; do
        if [[ -f "$dir/$lockfile" ]] && [[ "$dir/$lockfile" -nt "$dir/node_modules" ]]; then
            info "Lock file newer than node_modules, will reinstall" >&2
            return 0
        fi
    done

    # node_modules exists and is up-to-date
    return 1
}

# List existing worktrees via SideQuest CLI (excluding main)
list_for_picker_cli() {
    local json_output
    json_output=$($SIDEQUEST_GIT_CMD worktree list --json 2>/dev/null) || return 1
    echo "$json_output" | jq -r '.[] | select(.isMain == false) | "\(.branch)\t\(.path)\t\(.status // "unknown")"'
}

# List existing worktrees (excluding main)
list_worktrees() {
    local repo_root
    repo_root=$(get_repo_root)

    # Use process substitution to avoid subshell variable scope issue
    while read -r wt; do
        [[ -z "$wt" ]] && continue
        # Skip if it's the main worktree
        if [[ "$wt" != "$repo_root" ]]; then
            local branch
            branch=$(git -C "$wt" branch --show-current 2>/dev/null || echo "detached")
            echo "worktree:$branch:$wt"
        fi
    done < <(git worktree list --porcelain | grep "^worktree " | cut -d' ' -f2-)
}

# List ALL remote branches (as bases for new branches), newest first
list_remote_branches() {
    git branch -r --sort=-committerdate 2>/dev/null | grep -v HEAD | sed 's/.*origin\///' | while read -r branch; do
        echo "remote:$branch"
    done
}

# List ALL local branches (as bases for new branches), newest first
list_local_branches() {
    git branch --sort=-committerdate --format='%(refname:short)' | while read -r branch; do
        echo "local:$branch"
    done
}

# Show fzf picker for branch/worktree selection
pick_branch() {
    local choices=""

    # Header option to create new branch from HEAD
    choices="${CYAN}[+] Create new branch (from HEAD)${NC}\n"

    # Existing worktrees (can attach)
    local worktrees
    worktrees=$(list_worktrees)
    if [[ -n "$worktrees" ]]; then
        choices+="${GREEN}── Attach to Worktree ──${NC}\n"
        choices+="$worktrees\n"
    fi

    # Local branches
    local local_branches
    local_branches=$(list_local_branches)
    if [[ -n "$local_branches" ]]; then
        choices+="${YELLOW}── Local Branches ──${NC}\n"
        choices+="$local_branches\n"
    fi

    # Remote branches
    local remote_branches
    remote_branches=$(list_remote_branches)
    if [[ -n "$remote_branches" ]]; then
        choices+="${BLUE}── Remote Branches ──${NC}\n"
        choices+="$remote_branches\n"
    fi

    # Use fzf to pick (no --height in popup, it takes full space)
    local selection
    selection=$(echo -e "$choices" | fzf --ansi --reverse \
        --header="Select base branch or existing worktree" \
        --no-preview) || exit 0

    echo "$selection"
}

# Prompt for new branch name - sets REPLY variable directly
# Args: $1 = base branch (optional, for display)
prompt_new_branch() {
    local base="${1:-HEAD}"
    # After fzf exits, stdin might be weird - explicitly use /dev/tty
    exec < /dev/tty
    echo ""
    printf "${DIM}Base: ${base}${NC}\n"
    printf "${CYAN}Enter new branch name: ${NC}"
    read -r REPLY

    if [[ -z "$REPLY" ]]; then
        error "Branch name cannot be empty"
    fi

    # Sanitize branch name (allow slashes for feat/xxx style)
    REPLY=$(echo "$REPLY" | sed 's/[^a-zA-Z0-9._/-]/-/g')
}

# Create or get worktree path via SideQuest CLI
# Args: $1 = new branch name, $2 = base branch (optional)
ensure_worktree_cli() {
    local branch="$1"
    local base_branch="${2:-}"
    local stderr_file
    stderr_file=$(mktemp)

    # Build args array
    local -a args=("worktree" "create" "$branch" "--no-fetch" "--no-install" "--json")
    if [[ -n "$base_branch" ]]; then
        args+=("--base" "$base_branch")
    fi

    local repo_root
    repo_root=$(get_repo_root)
    local sanitized_branch="${branch//\//-}"
    local worktree_path="${repo_root}/.worktrees/${sanitized_branch}"

    # Check if worktree already exists before creating
    if sidequest_check_worktree_exists "$worktree_path"; then
        info "Worktree already exists at $worktree_path, skipping creation"
        echo "$worktree_path"
        return 0
    fi

    # Run create via CLI
    local json_output exit_code
    json_output=$($SIDEQUEST_GIT_CMD "${args[@]}" 2>"$stderr_file")
    exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        local err_msg
        err_msg=$(jq -r '.error // "unknown error"' <<< "$(cat "$stderr_file")" 2>/dev/null || cat "$stderr_file")
        sidequest_error "create" "$err_msg" "$SIDEQUEST_GIT_CMD ${args[*]}" "git worktree remove --force \"$worktree_path\""
        sidequest_log "cli" "create" "$branch" "$exit_code" "$err_msg"
        sidequest_recover_create "$worktree_path"
        rm -f "$stderr_file"
        return 1
    fi

    # Parse path from JSON output
    local created_path
    created_path=$(jq -r '.path' <<< "$json_output")
    sidequest_log "cli" "create" "$branch" "0"

    # Install sequence: switch node -> verify -> install
    if [[ -d "$created_path" ]]; then
        switch_node_version "$created_path"
        sidequest_verify_node

        # Run install via CLI
        local install_output install_exit
        install_output=$($SIDEQUEST_GIT_CMD worktree install "$created_path" --json 2>"$stderr_file")
        install_exit=$?

        if [[ $install_exit -ne 0 ]]; then
            local install_err
            install_err=$(jq -r '.error // "unknown error"' <<< "$(cat "$stderr_file")" 2>/dev/null || cat "$stderr_file")
            sidequest_error "install" "$install_err" "$SIDEQUEST_GIT_CMD worktree install \"$created_path\" --json" "cd \"$created_path\" && npm install"
            sidequest_log "cli" "install" "$created_path" "$install_exit" "$install_err"
            # Keep worktree, open session anyway (unbootstrapped)
            warning "Install failed - worktree created but packages not installed"
        else
            sidequest_log "cli" "install" "$created_path" "0"
        fi
    fi

    rm -f "$stderr_file"
    echo "$created_path"
    return 0
}

# Create or get worktree path for a branch
# Args: $1 = new branch name, $2 = base branch (optional)
ensure_worktree() {
    # SideQuest CLI dispatch
    if [[ "${USE_SIDEQUEST:-0}" == "1" ]]; then
        sidequest_preflight
        if [[ "${USE_SIDEQUEST:-0}" == "1" ]]; then
            ensure_worktree_cli "$@"
            return $?
        fi
    fi
    local branch="$1"
    local base="${2:-}"
    local repo_root
    repo_root=$(get_repo_root)

    # Sanitize branch name for path (replace / with -)
    local path_safe_branch
    path_safe_branch=$(echo "$branch" | tr '/' '-')
    local worktree_path="$repo_root/$WORKTREE_DIR/$path_safe_branch"

    # Check if worktree already exists for this branch
    if git worktree list --porcelain | grep -q "^worktree $worktree_path$"; then
        echo "$worktree_path"
        return 0
    fi

    # Create worktrees directory if needed
    mkdir -p "$repo_root/$WORKTREE_DIR"

    # If base is specified, create new branch from that base
    if [[ -n "$base" ]]; then
        # Check if it's a remote base
        if [[ "$base" == origin/* ]] || git show-ref --verify --quiet "refs/remotes/origin/$base"; then
            local remote_ref="origin/$base"
            [[ "$base" == origin/* ]] && remote_ref="$base"
            info "Creating worktree: $branch from $remote_ref" >&2
            if ! git worktree add -b "$branch" "$worktree_path" "$remote_ref" >&2; then
                error "Failed to create worktree from $remote_ref"
            fi
        else
            # Local base
            info "Creating worktree: $branch from $base" >&2
            if ! git worktree add -b "$branch" "$worktree_path" "$base" >&2; then
                error "Failed to create worktree from $base"
            fi
        fi
    # No base specified - check if branch exists
    elif git show-ref --verify --quiet "refs/heads/$branch"; then
        info "Creating worktree for existing branch: $branch" >&2
        if ! git worktree add "$worktree_path" "$branch" >&2; then
            error "Failed to create worktree for branch $branch"
        fi
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        info "Creating worktree for remote branch: $branch" >&2
        if ! git worktree add "$worktree_path" -b "$branch" "origin/$branch" >&2; then
            error "Failed to create worktree from origin/$branch"
        fi
    else
        # New branch from origin/master (or origin/main)
        local default_base="origin/master"
        if ! git show-ref --verify --quiet "refs/remotes/origin/master"; then
            if git show-ref --verify --quiet "refs/remotes/origin/main"; then
                default_base="origin/main"
            fi
        fi
        info "Creating worktree with new branch: $branch (from $default_base)" >&2
        if ! git worktree add -b "$branch" "$worktree_path" "$default_base" >&2; then
            error "Failed to create worktree for new branch $branch"
        fi
    fi

    # Copy untracked files from main worktree to new worktree
    copy_untracked_files "$repo_root" "$worktree_path"

    # Install dependencies if this is a JS/TS project
    run_package_install "$worktree_path"

    echo "$worktree_path"
}

# Create tmux session with standard template (using raw tmux commands)
create_ai_session() {
    local worktree_path="$1"
    local branch="$2"
    local repo_name
    repo_name=$(basename "$(get_repo_root)")

    # Session name: repo-wt-branch (sanitized, kebab-case)
    # IMPORTANT: Replace dots with hyphens - dots break tmux target syntax (session:window.pane)
    local safe_repo_name
    safe_repo_name=$(echo "$repo_name" | tr '.' '-')
    local session_name
    # Also replace dots in branch name (e.g., v1.2.3 -> v1-2-3)
    session_name="${safe_repo_name}-wt-$(echo "$branch" | tr '/' '-' | tr '.' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-30)"

    # Ensure cache directory exists
    mkdir -p "$(dirname "$SESSION_FILE")"

    # Check if session already exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
        success "Session '$session_name' exists"
        echo "$session_name" > "$SESSION_FILE"
        return
    fi

    info "Creating session '$session_name'..."

    # Create new detached session with 'ai' window
    if ! tmux new-session -d -s "$session_name" -n "ai" -c "$worktree_path"; then
        error "Failed to create session '$session_name'"
    fi

    # Write session name IMMEDIATELY so switch works even if pane setup fails
    echo "$session_name" > "$SESSION_FILE"

    # Get pane base index (default is 0, but tmux.conf may set to 1)
    local pane_base
    pane_base=$(tmux show-options -gv pane-base-index 2>/dev/null || echo 0)

    # Split into 4 panes (tiled layout) - continue on error
    tmux split-window -t "$session_name:ai" -h -c "$worktree_path" 2>/dev/null || true
    tmux split-window -t "$session_name:ai.$pane_base" -v -c "$worktree_path" 2>/dev/null || true
    tmux split-window -t "$session_name:ai.$((pane_base + 1))" -v -c "$worktree_path" 2>/dev/null || true
    tmux select-layout -t "$session_name:ai" tiled 2>/dev/null || true

    # Start Claude in each pane with staggered delays
    tmux send-keys -t "$session_name:ai.$pane_base" "ccdev" C-m 2>/dev/null || true
    tmux send-keys -t "$session_name:ai.$((pane_base + 1))" "sleep 2 && ccdev" C-m 2>/dev/null || true
    tmux send-keys -t "$session_name:ai.$((pane_base + 2))" "sleep 4 && ccdev" C-m 2>/dev/null || true
    tmux send-keys -t "$session_name:ai.$((pane_base + 3))" "sleep 6 && ccdev" C-m 2>/dev/null || true

    # Add git window with lazygit
    tmux new-window -t "$session_name" -n "git" -c "$worktree_path" 2>/dev/null || true
    tmux send-keys -t "$session_name:git" "lazygit" C-m 2>/dev/null || true

    # Add shell window
    tmux new-window -t "$session_name" -n "shell" -c "$worktree_path" 2>/dev/null || true

    # Select the ai window and first pane
    tmux select-window -t "$session_name:ai" 2>/dev/null || true
    tmux select-pane -t "$session_name:ai.$pane_base" 2>/dev/null || true

    success "Created session '$session_name'"
    echo "Worktree: $worktree_path"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    check_git_repo

    # Clean up any stale session file from previous runs
    cleanup_session_file

    # Fetch latest from remote (prune deleted branches)
    info "Fetching latest from remote..."
    git fetch --prune --quiet 2>/dev/null || warning "Could not fetch from remote"

    local branch=""
    local worktree_path=""

    if [[ -n "$1" ]]; then
        # Branch name provided as argument
        branch="$1"
    else
        # Show picker
        local selection
        selection=$(pick_branch)

        if [[ "$selection" == *"Create new branch"* ]]; then
            prompt_new_branch "HEAD"
            branch="$REPLY"
        elif [[ "$selection" == worktree:* ]]; then
            # Existing worktree - extract path and branch
            branch=$(echo "$selection" | cut -d: -f2)
            worktree_path=$(echo "$selection" | cut -d: -f3)
        elif [[ "$selection" == local:* ]]; then
            # Local branch selected
            branch=$(echo "$selection" | cut -d: -f2)
            # Check if this branch already has a worktree - if so, just attach
            if branch_has_worktree "$branch"; then
                worktree_path=$(get_worktree_path_for_branch "$branch")
            fi
            # Otherwise create worktree for this branch
        elif [[ "$selection" == remote:* ]]; then
            # Remote branch selected
            branch=$(echo "$selection" | cut -d: -f2)
            # Check if local equivalent already has a worktree - if so, just attach
            if branch_has_worktree "$branch"; then
                worktree_path=$(get_worktree_path_for_branch "$branch")
            fi
            # Otherwise checkout the remote branch into new worktree
        else
            exit 0
        fi
    fi

    # Ensure worktree exists (skip if we already have the path)
    # Note: ensure_worktree handles branch detection automatically:
    # - Existing local branch: creates worktree for it
    # - Remote branch: creates local tracking branch from origin/branch
    # - New branch name: creates from HEAD
    local is_new_worktree=false
    if [[ -z "$worktree_path" ]]; then
        is_new_worktree=true
        worktree_path=$(ensure_worktree "$branch")
    fi

    # Bootstrap existing worktrees (new worktrees are bootstrapped in ensure_worktree)
    # This ensures attaching to an existing worktree also gets fresh untracked files
    if [[ "$is_new_worktree" == false ]]; then
        local repo_root
        repo_root=$(get_repo_root)

        # Copy untracked files (safe to re-run, skips existing)
        copy_untracked_files "$repo_root" "$worktree_path"

        # Only run install if node_modules is missing or stale
        if should_run_install "$worktree_path"; then
            run_package_install "$worktree_path"
        fi
    fi

    # Create the AI session
    create_ai_session "$worktree_path" "$branch"
}

main "$@"
