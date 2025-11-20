# VS Code Copilot Prompt Files

This directory contains Copilot prompt files that integrate with the Claude Code task management workflow.

**For complete documentation, see [../README.md](../README.md)**

## Prompt Files

- **Next.prompt.md** - `/next` command for starting tasks
- **Merge.prompt.md** - `/merge` command for PR merging and cleanup
- **SETTINGS.md** - Detailed auto-approval configuration guide

## Delegation Pattern

These prompts delegate to Claude Code command files for instructions:
- `/next` → Reads `~/.claude/commands/next.md`
- `/merge` → Reads `~/.claude/commands/merge.md`

This ensures a single source of truth and automatic updates when command files change.
