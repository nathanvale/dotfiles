# NPM Install in Worktrees: Deep Analysis

**Date:** 2025-11-17 **Analysis:** Comparing GTR, incident.io, and our current implementation

---

## Executive Summary

After analyzing git-worktree-runner (GTR), incident.io's production usage, and our current
implementation, here's what we found:

**Current Implementation Rating:** ⭐⭐⭐⭐ (4/5) **Key Finding:** Our approach is actually
**superior** to GTR in some ways, but we're missing **hook flexibility** and **error handling**.

---

## The Three Approaches

### 1. GTR's Approach: Hook-Based System

**Philosophy:** Offload all dependency installation to user-configurable hooks

**Implementation:**

```bash
# User configures hooks via git config
gtr config add gtr.hook.postCreate "npm install"
gtr config add gtr.hook.postCreate "npm run build"

# GTR executes hooks after worktree creation
run_hooks_in "postCreate" "$WORKTREE_PATH" \
  "REPO_ROOT=$repo_root" \
  "WORKTREE_PATH=$worktree_path" \
  "BRANCH=$branch"
```

**Pros:**

- ✅ **Ultimate flexibility** - User controls everything
- ✅ **Cross-platform** - Works with any build tool (npm, pnpm, cargo, pip, etc.)
- ✅ **Environment variables** - Hooks receive context via env vars
- ✅ **Multi-step builds** - Chain multiple commands
- ✅ **Isolation** - Each hook runs in subshell

**Cons:**

- ❌ **Requires setup** - User must configure hooks per repo
- ❌ **No defaults** - Zero auto-detection
- ❌ **No monorepo awareness** - User must handle `--filter` manually
- ❌ **Silent failures** - Hooks fail but worktree still created

**GTR Hook System Code:**

```bash
# From lib/hooks.sh
run_hooks() {
  local phase="$1"
  shift

  local hooks=$(cfg_get_all "gtr.hook.$phase")

  if [ -z "$hooks" ]; then
    return 0  # No hooks = no action
  fi

  log_step "Running $phase hooks..."

  # Execute each hook in subshell
  while IFS= read -r hook; do
    if (
      for kv in "${envs[@]}"; do
        export "$kv"
      done
      eval "$hook"  # Execute hook command
    ); then
      log_info "Hook completed successfully"
    else
      log_error "Hook failed with exit code $?"
      failed=$((failed + 1))
    fi
  done <<EOF
$hooks
EOF

  return $failed
}
```

---

### 2. incident.io's Approach: Script-Based Wrapper

**Philosophy:** Automate the entire worktree lifecycle with bash function

**Implementation:**

```bash
# From their blog post - the `w` function
w() {
  local repo=$1
  local worktree=$2
  local cmd=$3

  # Auto-creates worktree if doesn't exist
  # Runs command in worktree context
  # No mention of dependency installation in their blog
}
```

**Key Insight from Blog:**

> "Our CI runs in under five minutes"

**What they DON'T mention:**

- How they handle `npm install` in worktrees
- Whether they copy `node_modules` or reinstall
- How they manage monorepo dependencies
- Database setup for each worktree

**Our Hypothesis:** They likely rely on **fast CI with preview environments** rather than local
dependency installation. Their worktrees might be primarily for **code changes**, with **testing
happening in CI**.

---

### 3. Our Current Approach: Smart Auto-Detection

**Philosophy:** Intelligent defaults with auto-detection, handle common cases automatically

**Implementation:**

```bash
# 1. Auto-detect package manager
if [ -f "$WORKTREE_ABS_PATH/pnpm-lock.yaml" ]; then
    PKG_MGR="pnpm"
elif [ -f "$WORKTREE_ABS_PATH/yarn.lock" ]; then
    PKG_MGR="yarn"
elif [ -f "$WORKTREE_ABS_PATH/bun.lockb" ]; then
    PKG_MGR="bun"
elif [ -f "$WORKTREE_ABS_PATH/package-lock.json" ]; then
    PKG_MGR="npm"
fi

# 2. Auto-detect monorepo package
if [ "$IS_MONOREPO" = true ] && [ "$PKG_MGR" = "pnpm" ]; then
    PACKAGE_NAME=$(echo "$TASK_FILE_PATH" | sed 's|^\./||' | cut -d'/' -f1-2)
    if [ -n "$PACKAGE_NAME" ]; then
        (cd "$WORKTREE_ABS_PATH" && $PKG_MGR install --filter "$PACKAGE_NAME")
    fi
else
    (cd "$WORKTREE_ABS_PATH" && $PKG_MGR install)
fi

# 3. Suppress deprecation warnings
| grep -v "deprecated" || true
```

**Pros:**

- ✅ **Zero configuration** - Works out of the box
- ✅ **Monorepo-aware** - Detects packages automatically
- ✅ **Smart filtering** - Uses `pnpm --filter` for monorepos
- ✅ **Multi-package-manager** - Supports npm, pnpm, yarn, bun
- ✅ **Clean output** - Filters noise
- ✅ **Task-driven** - Knows which package to install from task file

**Cons:**

- ❌ **Hardcoded** - No user control over install process
- ❌ **No hooks** - Can't run custom post-install commands
- ❌ **Error handling** - `|| true` swallows all errors
- ❌ **No parallelization** - Runs serially
- ❌ **Limited flexibility** - Can't customize install flags

---

## Detailed Comparison Matrix

| Feature                           | GTR        | incident.io | Our Implementation | Winner          |
| --------------------------------- | ---------- | ----------- | ------------------ | --------------- |
| **Auto-detect package manager**   | ❌         | Unknown     | ✅                 | **Us**          |
| **Monorepo support**              | ❌ Manual  | Unknown     | ✅ Auto            | **Us**          |
| **Configurability**               | ✅✅ Hooks | ❌          | ❌                 | **GTR**         |
| **Zero-config workflow**          | ❌         | ✅          | ✅                 | **Us/incident** |
| **Custom post-install steps**     | ✅ Hooks   | ❌          | ❌                 | **GTR**         |
| **Error handling**                | ⚠️ Logs    | Unknown     | ❌                 | **GTR**         |
| **Cross-platform (Rust, Python)** | ✅         | ✅          | ❌                 | **GTR**         |
| **pnpm workspace filtering**      | ❌ Manual  | Unknown     | ✅ Auto            | **Us**          |
| **Suppress noise**                | ❌         | Unknown     | ✅                 | **Us**          |
| **Build step automation**         | ✅ Hooks   | CI-based    | ❌                 | **GTR**         |

---

## Real-World Production Insights

### What incident.io Actually Does

From their blog post analysis:

**Evidence 1: Fast iteration**

> "$8 of Claude credit later, it had produced a full analysis... 18% (30 seconds) improvement"

**Evidence 2: CI-centric**

> "We already have previews automatically generated for frontend code changes in pull requests,
> which run against our staging infrastructure"

**Evidence 3: Resource constraints**

> "Running several Claude sessions simultaneously means juggling databases, ports, and local
> services—which quickly becomes unwieldy"

**Conclusion:** incident.io likely uses worktrees for **code changes only**, relying on **CI for
builds and tests**. They mention "preview environments" extensively but never mention local
`npm install`.

---

## The REAL Problem with NPM Installs in Worktrees

### Issue 1: Redundant Installation

**Problem:** Each worktree runs `npm install` independently, duplicating work.

**Example:**

```
Main repo:          pnpm install (5 min)
Worktree T0001:     pnpm install (5 min)  ← Duplicate!
Worktree T0002:     pnpm install (5 min)  ← Duplicate!
Worktree T0003:     pnpm install (5 min)  ← Duplicate!
```

**Total time:** 20 minutes for 4 worktrees 😱

### Issue 2: Disk Space Waste

**Problem:** Each worktree creates its own `node_modules/`

**Calculation:**

```
node_modules/: 2GB per worktree
4 worktrees:   8GB total
10 worktrees:  20GB total
```

### Issue 3: Conflicting Ports/Databases

**Problem:** Multiple dev servers can't run on same port

**Example:**

```
Worktree 1: npm run dev → Port 3000 ✅
Worktree 2: npm run dev → Port 3000 ❌ CONFLICT
```

---

## Best Practices from Production

### GTR's Recommendation

**From their README:**

```bash
# Example setup for Node.js
gtr config add gtr.hook.postCreate "pnpm install"
gtr config add gtr.hook.postCreate "pnpm run build"

# Example for Python
gtr config add gtr.hook.postCreate "pip install -r requirements.txt"

# Example for Rust
gtr config add gtr.hook.postCreate "cargo build"
```

**Key insight:** GTR treats all languages equally via hooks.

### incident.io's Approach

**From their workflow description:**

1. Create worktree (instant)
2. Make code changes with Claude
3. **Push to CI** for build/test
4. Get preview environment link
5. Review in browser

**Key insight:** They **avoid local builds entirely** by pushing to CI.

### What Works in Practice

**For small projects (<100 packages):**

- ✅ Run `npm install` in each worktree
- ✅ Accept some duplication
- ✅ Keep it simple

**For large monorepos (100+ packages):**

- ✅ Use pnpm workspaces (shared node_modules)
- ✅ Use `--filter` for targeted installs
- ✅ Consider skipping install if package unchanged

**For maximum parallelism:**

- ✅ Skip local installs entirely
- ✅ Push to CI for builds
- ✅ Use preview environments

---

## What We're Doing Right

### 1. Monorepo Intelligence ✅

**Our code:**

```bash
if [ "$IS_MONOREPO" = true ] && [ "$PKG_MGR" = "pnpm" ]; then
    PACKAGE_NAME=$(echo "$TASK_FILE_PATH" | sed 's|^\./||' | cut -d'/' -f1-2)
    if [ -n "$PACKAGE_NAME" ]; then
        (cd "$WORKTREE_ABS_PATH" && $PKG_MGR install --filter "$PACKAGE_NAME")
    fi
fi
```

**Why this is smart:**

- Detects package from task file path
- Uses pnpm's `--filter` for targeted installs
- Avoids installing entire monorepo

**GTR equivalent:** User must manually configure this.

### 2. Multi-Package-Manager Support ✅

**Our detection logic:**

```bash
if [ -f "$WORKTREE_ABS_PATH/pnpm-lock.yaml" ]; then PKG_MGR="pnpm"
elif [ -f "$WORKTREE_ABS_PATH/yarn.lock" ]; then PKG_MGR="yarn"
elif [ -f "$WORKTREE_ABS_PATH/bun.lockb" ]; then PKG_MGR="bun"
elif [ -f "$WORKTREE_ABS_PATH/package-lock.json" ]; then PKG_MGR="npm"
fi
```

**Why this is valuable:**

- Works across all projects without configuration
- Respects project's chosen package manager
- Automatic and invisible to user

### 3. Noise Suppression ✅

**Our approach:**

```bash
(cd "$WORKTREE_ABS_PATH" && $PKG_MGR install) 2>&1 | grep -v "deprecated" || true
```

**Benefits:**

- Cleaner output for users
- Focuses on actual errors
- Less visual clutter

---

## What We're Doing Wrong

### 1. Error Swallowing ❌

**Current code:**

```bash
| grep -v "deprecated" || true
```

**Problem:** The `|| true` means installation failures are ignored!

**Example failure:**

```bash
$ pnpm install --filter apps/api
Error: Package "@types/node" not found
$ echo $?
0  ← Exits success due to || true!
```

**Fix needed:**

```bash
# Better approach
if ! (cd "$WORKTREE_ABS_PATH" && $PKG_MGR install 2>&1 | grep -v "deprecated"); then
    echo "⚠️  Warning: Package installation had issues"
    echo "   Worktree created but may need manual setup"
fi
```

### 2. No Hook System ❌

**Current code:** Hardcoded install, no customization

**What we're missing:**

```bash
# What GTR allows
gtr config add gtr.hook.postCreate "pnpm install"
gtr config add gtr.hook.postCreate "pnpm run db:migrate"
gtr config add gtr.hook.postCreate "pnpm run build"

# What we need
git config --add claude.hook.postCreate "pnpm install"
git config --add claude.hook.postCreate "pnpm run db:setup"
```

### 3. No Skip Option ❌

**Current code:** Always runs install, no way to disable

**What users might want:**

```bash
# Skip install for quick worktree creation
create-worktree.sh T0001 --no-install

# Or via git config
git config --bool claude.worktree.autoInstall false
```

### 4. No Parallelization ❌

**Current code:** Runs install synchronously

**What we could do:**

```bash
# Launch multiple worktree creations in parallel
parallel-worktree-create.sh T0001 T0002 T0003 T0004

# Each runs install in background
# Wait for all to complete
```

---

## Recommendations

### Tier 1: Must-Have Improvements

**1. Fix Error Handling**

```bash
# Current (WRONG)
(cd "$WORKTREE_ABS_PATH" && $PKG_MGR install) 2>&1 | grep -v "deprecated" || true

# Fixed (CORRECT)
echo "Installing dependencies..."
if (cd "$WORKTREE_ABS_PATH" && $PKG_MGR install 2>&1 | grep -v "deprecated"); then
    echo "✓ Dependencies installed"
else
    echo "⚠️  Package installation failed - worktree created but may need manual setup"
    echo "   Try running: cd $WORKTREE_ABS_PATH && $PKG_MGR install"
fi
```

**2. Add Hook System (GTR-style)**

```bash
# Read hooks from git config
HOOKS=$(git config --get-all claude.hook.postCreate 2>/dev/null || echo "")

if [ -n "$HOOKS" ]; then
    echo "Running post-create hooks..."
    while IFS= read -r hook; do
        [ -z "$hook" ] && continue
        echo "→ $hook"
        if (cd "$WORKTREE_ABS_PATH" && eval "$hook"); then
            echo "  ✓ Completed"
        else
            echo "  ⚠️  Failed (exit code $?)"
        fi
    done <<< "$HOOKS"
fi
```

**3. Add `--no-install` Flag**

```bash
# In argument parsing
NO_INSTALL=false
if [[ "$*" =~ --no-install ]]; then
    NO_INSTALL=true
fi

# Before install section
if [ "$NO_INSTALL" = true ]; then
    echo "⏭️  Skipping dependency installation (--no-install)"
else
    # ... existing install logic ...
fi
```

### Tier 2: Nice-to-Have Enhancements

**4. Smart Caching**

```bash
# Check if dependencies actually changed
if [ -f "$MAIN_REPO_ROOT/package-lock.json" ] && \
   [ -f "$WORKTREE_ABS_PATH/package-lock.json" ]; then
    if diff -q "$MAIN_REPO_ROOT/package-lock.json" "$WORKTREE_ABS_PATH/package-lock.json" > /dev/null; then
        echo "📦 Dependencies unchanged - skipping install"
        NO_INSTALL=true
    fi
fi
```

**5. Progress Indicators**

```bash
# Show progress for long installs
echo "Installing dependencies (this may take a moment)..."
(cd "$WORKTREE_ABS_PATH" && $PKG_MGR install) &
INSTALL_PID=$!

# Show spinner while waiting
while kill -0 $INSTALL_PID 2>/dev/null; do
    echo -n "."
    sleep 1
done
wait $INSTALL_PID
```

**6. Parallel Install Support**

```bash
# When creating multiple worktrees, install in parallel
for task in T0001 T0002 T0003; do
    create-worktree.sh $task --async &
done
wait  # Wait for all to complete
```

### Tier 3: Advanced Features

**7. Shared node_modules (pnpm style)**

```bash
# Symlink to shared node_modules if using pnpm
if [ "$PKG_MGR" = "pnpm" ]; then
    # pnpm already does this via store
    # No action needed
fi
```

**8. CI-Only Mode (incident.io style)**

```bash
# Skip all local setup, rely on CI
git config --bool claude.worktree.ciOnly true

# In script
if [ "$(git config --bool claude.worktree.ciOnly)" = "true" ]; then
    echo "🚀 CI-only mode - skipping local setup"
    echo "   Push changes to trigger CI builds"
    exit 0
fi
```

---

## Conclusion

**Our Current Implementation:** ⭐⭐⭐⭐ (4/5)

**What we're doing better than GTR:**

- ✅ Monorepo intelligence
- ✅ Zero-configuration auto-detection
- ✅ Clean output

**What GTR does better:**

- ✅ Hook flexibility
- ✅ Error visibility
- ✅ Cross-platform (not just JS)

**What incident.io teaches us:**

- ✅ Consider CI-centric workflows
- ✅ Don't over-invest in local builds
- ✅ Fast iteration > perfect setup

**Recommended Action Plan:**

1. **Immediate** (this week):
   - Fix error handling (`|| true` removal)
   - Add basic hook system
   - Add `--no-install` flag

2. **Short-term** (this month):
   - Implement smart caching
   - Add progress indicators
   - Document git config options

3. **Long-term** (when needed):
   - Parallel install support
   - CI-only mode
   - Shared dependency strategies

**Bottom line:** We're 90% there. The main gaps are **error handling** and **extensibility via
hooks**. Fix those, and we'll have a best-in-class implementation.
