# Quality Gates for Task Completion

## The Cardinal Rule

**A task can NEVER be marked as COMPLETED if any validation check fails.**

No exceptions. No "it was already broken" excuses. No "I'll fix it later" promises.

## Required Validation Checks

Before marking any task as COMPLETED, ALL of the following must pass:

### ✅ Type Checking
```bash
pnpm typecheck  # or npm run typecheck, tsc --noEmit, etc.
```
- **Must return**: Exit code 0
- **No errors allowed**: Not even "errors in dependencies"
- **Pre-existing errors**: Stop and fix the build first

### ✅ Linting
```bash
pnpm lint  # or npm run lint, eslint ., etc.
```
- **Must return**: Exit code 0
- **No errors allowed**: Warnings are ok, errors are not
- **Auto-fixable**: Run `pnpm lint --fix` first

### ✅ Testing
```bash
pnpm test  # or npm test, jest, vitest, etc.
```
- **Must return**: Exit code 0
- **All tests passing**: 100% pass rate required
- **No skipped tests**: Due to errors (skipped by design is ok)
- **Test timeouts**: Increase timeout or fix the test

### ✅ Formatting
```bash
pnpm format  # or prettier --check, etc.
```
- **Must return**: Exit code 0
- **No formatting issues**: Run `pnpm format` to auto-fix
- **Consistent style**: Follow project conventions

## Handling Failures

### Scenario 1: Your Code Broke It

**What to do:**
1. Read the error message carefully
2. Use Edit tool to fix the issue
3. Re-run the validation
4. Repeat until passing
5. Commit the fix
6. Only then mark as COMPLETED

**Example:**
```bash
# Oh no, tests are failing
pnpm test
# ❌ FAIL  src/utils/retry.test.ts
#   Expected: 3, Received: 5

# Fix it
# Edit the test or implementation

# Re-validate
pnpm test
# ✅ PASS  src/utils/retry.test.ts
# All tests passed!

# Now you can mark as COMPLETED
```

### Scenario 2: Pre-existing Failures (Main is Broken)

**This is serious and requires a different approach.**

#### Step 1: Verify Main is Broken
```bash
# Save your work
git stash

# Check main branch
git checkout main
pnpm install
pnpm test

# If tests fail on main, the build is broken
```

#### Step 2: Create a Fix-Build Task
```yaml
---
id: T0999
title: Fix broken build - test failures on main
priority: P0  # This is now highest priority!
status: READY
created: 2025-11-17
---

## Problem
Main branch has failing tests:
- test/portal.test.ts - Missing import
- test/stream.test.ts - Concurrency assertion error

## Acceptance Criteria
- All tests pass on main branch
- CI is green
- Build is stable

## Action Plan
1. Check out main branch
2. Run tests to reproduce
3. Fix each failing test
4. Ensure all checks pass
5. Create PR to main
6. Merge fix first
```

#### Step 3: Work on Fix-Build First
```bash
# Switch to fixing the build
/next  # Will pick up T0999 (P0)

# Fix all the issues
# Get everything passing
# Create PR
# Merge to main
```

#### Step 4: Return to Original Task
```bash
# Now go back to your original task
git checkout feat/T0035-your-feature

# Rebase on fixed main
git rebase main

# Re-run validation (should pass now)
pnpm test
# ✅ All tests passed!

# NOW you can mark T0035 as COMPLETED
```

### Scenario 3: Can't Fix After Multiple Attempts

If you've genuinely tried 3+ times and cannot resolve the issue:

**What to do:**
1. **Leave task as IN_PROGRESS** (not COMPLETED!)
2. Document the blocker in task file:
   ```yaml
   ---
   id: T0035
   status: IN_PROGRESS  # ← Still in progress!
   blockers:
     - "Tests fail with timeout on CI but pass locally"
     - "Suspected flaky test, needs investigation"
     - "Tried: increasing timeout, mocking time, isolating test"
   ---
   ```

3. Create PR as **DRAFT**:
   ```bash
   gh pr create --draft \
     --title "[WIP] feat(T0035): Feature name" \
     --body "⚠️ DRAFT: Tests failing, needs investigation

   ## Status
   - ✅ Implementation complete
   - ✅ Typecheck passes
   - ✅ Lint passes
   - ❌ Tests failing (timeout issue)

   ## Blocker
   Tests fail with timeout on CI but pass locally.
   Need help investigating flaky test behavior.

   ## Request
   Please review the approach and help debug the test failure."
   ```

4. Ask user for guidance:
   ```
   I've completed the implementation for T0035, but tests are failing
   with a timeout issue that I can't resolve. The tests pass locally
   but fail on CI.

   I've created a draft PR with details. Can you help investigate?

   Should I:
   1. Continue debugging the test?
   2. Skip the problematic test temporarily?
   3. Create a separate task to fix the flaky test?
   ```

## Common Mistakes

### ❌ "It was already broken"
**Wrong approach:**
```
Tests are failing, but they were already failing on main,
so I'll just mark this as done.
```

**Right approach:**
```
Tests are failing. Let me check if main is broken.
[Checks main] Yes, main is broken.
I'll create a P0 task to fix the build first.
```

### ❌ "I'll fix it in the next task"
**Wrong approach:**
```
I'll merge this with failing tests and fix it in the next task.
```

**Right approach:**
```
I cannot merge failing tests. I'll fix them now before marking
this task as complete.
```

### ❌ "The tests are flaky anyway"
**Wrong approach:**
```
These tests are flaky, so I'll just ignore the failures.
```

**Right approach:**
```
These tests are flaky. I'll either:
1. Fix the flaky tests, or
2. Create a task to fix flaky tests, or
3. Document the flakiness and get user approval
before marking this complete.
```

## Why This Matters

### For Solo Developers
- Prevents you from breaking your own build
- Maintains a clean, working main branch
- Avoids the "death by a thousand cuts" scenario
- Forces you to fix problems immediately

### For Teams
- Prevents blocking other developers
- Maintains CI/CD pipeline health
- Ensures code review focuses on logic, not "does it build?"
- Respects everyone's time

### For Production
- Reduces deployment failures
- Prevents production incidents
- Maintains code quality
- Builds confidence in the codebase

## The /next Command Enforcement

The `/next` command is designed to enforce these quality gates:

**Step 5.6: Validation Phase**
```
Run all validation checks.
If any fail, fix and re-run.
Do NOT proceed to Step 6 until all pass.
```

**Step 6: Complete Task**
```
⚠️ VALIDATION GATE: DO NOT PROCEED UNLESS:
- ✅ All tests pass
- ✅ All type checks pass
- ✅ All linters pass
- ✅ Code is formatted
```

**Step 6.1: Update Task File**
```
Only after all validation passes, update task status to COMPLETED.
```

## Quick Reference

### Before Marking COMPLETED

Run this checklist:
```bash
# 1. Type check
pnpm typecheck || echo "❌ FAIL - Do not proceed"

# 2. Lint
pnpm lint || echo "❌ FAIL - Do not proceed"

# 3. Format
pnpm format || echo "❌ FAIL - Do not proceed"

# 4. Test
pnpm test || echo "❌ FAIL - Do not proceed"

# If all pass:
echo "✅ All validation passed - safe to mark COMPLETED"
```

### If Anything Fails

1. **Fix it now** (don't defer)
2. **Re-validate** (run the checks again)
3. **Repeat** until all pass
4. **Only then** mark as COMPLETED

## Remember

> "Working software is the primary measure of progress."
> — Agile Manifesto

If the tests don't pass, it's not working software. Period.
