---
name: "start-review"
description: "Decompose a review into individual task files"
argument-hint: "Optional: review name or leave empty to be prompted"
agent: "agent"
---

Follow the exact instructions defined in `~/.claude/commands/start-review.md` to execute the review
decomposition workflow.

If `~/.claude/commands/start-review.md` doesn't exist in this workspace, inform the user that this
workspace doesn't have the Claude Code task management system configured.

## Input

Review name (optional): ${input:reviewName:Enter review name or leave empty to be prompted}

**Execution:**

1. **Interactive Prompting:**
   - If review name not provided, ask user for it
   - Ask user for review source (file/task reference or paste content)
   - Ask for task prefix (default: MPCU-)

2. **Execute the review decomposition workflow** as defined in `~/.claude/commands/start-review.md`:
   - Create worktree for task generation
   - Parse review content
   - Decompose into task files
   - Commit and create PR

3. **Display comprehensive output** showing:
   - Worktree location and branch name
   - Task generation summary
   - PR creation details
   - Next steps for user

The workflow handles everything automatically as defined in the start-review command file.
