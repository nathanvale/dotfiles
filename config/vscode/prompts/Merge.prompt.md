---
name: "merge"
description: "Merge a PR and clean up worktree, branches, and locks"
argument-hint: "PR number, task ID (e.g., T0030, MPCU-0005), or leave empty for current worktree"
agent: "agent"
---

Follow the exact instructions defined in `~/.claude/commands/merge.md` to execute the merge workflow.

If `~/.claude/commands/merge.md` doesn't exist in this workspace, inform the user that this workspace doesn't have the Claude Code task management system configured.

## Input

PR/Task identifier: ${input:identifier:Enter PR number, task ID, or leave empty for current worktree}

**Execution:**

1. **Ask merge strategy using AskUserQuestion tool:**

   Ask the user to choose between:
   - **Manual Merge**: Merge the current branch directly into main, then delete branch and worktree (no PR)
   - **Create PR**: Create/merge a pull request with the standard workflow

2. **Based on user's choice:**

   **If Manual Merge:**
   - Detect current branch and worktree
   - Ask second question to confirm branch (using AskUserQuestion):
     * **Question:** "Confirm branch to merge and delete?"
     * **Option 1:** Use current branch (show branch name and worktree path)
     * **Option 2:** Enter branch name manually
   - Based on confirmation, run:
     * If current branch: `~/.claude/scripts/manual-merge.sh`
     * If manual: `~/.claude/scripts/manual-merge.sh <branch-name>`
   - Display the script output showing:
     * Branch being merged
     * Worktree removal
     * Branch deletion
     * Lock cleanup
     * Summary

   **If Create PR:**
   - Determine the script argument:
     - If user provided a number (e.g., `123`) → Use as argument
     - If user provided a task ID (e.g., `T0030`, `MPCU-0005`) → Use as argument
     - If empty or "current" → Use `--current` flag
   - Run the merge script:
     ```bash
     ~/.claude/scripts/merge-pr.sh <argument>
     ```
   - Display the comprehensive output from the script showing:
     - Git provider detection
     - PR verification
     - Merge operation
     - Cleanup steps
     - Summary

The script handles everything automatically as defined in the merge command file.
