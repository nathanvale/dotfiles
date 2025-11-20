---
name: "next"
description: "Start the next highest-priority task with atomic locking"
agent: "agent"
---

Follow the exact instructions defined in `~/.claude/commands/next.md` to execute the next task
workflow.

**Important reminders for VS Code Copilot execution:**

1. **Parse task JSON output directly** - Do NOT use bash `source` or environment variables. VS Code
   Copilot cannot access bash environment variables.

2. **Use literal file paths** - When the script outputs JSON, extract the literal `filePath` value
   and use it directly in tool calls.

3. **Execute scripts with bash** - Run `~/.claude/scripts/parse-next-task.sh --output-json` and
   parse the JSON response.

4. **CRITICAL: Call parse-next-task.sh ONLY ONCE** - The script atomically locks the task it
   returns. The returned task is YOUR lock - do NOT check if it's locked. Do NOT call the script
   again if you get a valid response.

Execute the workflow step-by-step as defined in the command file:

1. Find and atomically lock the next task (call script ONCE)
2. Read task requirements using literal path from JSON
3. Create worktree and setup environment
4. Guide task implementation
5. Create PR when complete
