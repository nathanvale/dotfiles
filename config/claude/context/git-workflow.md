# Git Workflow & Safety

## Git Safety Rules (CRITICAL)

### BLOCKED Commands (never use)

`git reset --hard`, `git reset HEAD~`, `git clean -f/-fd/-fx`, `git checkout -- .`, `git restore .`, `git push --force/-f`, `rm -rf`

### ASK FIRST (will prompt)

- `git rebase` — rewrites history
- `git stash drop` — permanently deletes stashed work
- `git branch -D` — force deletes branch

### SAFE Alternatives

- Use `git stash -u` instead of `git clean` to preserve untracked files
- Use `git stash` before risky operations (recoverable with `git stash pop`)
- Create backup branch first: `git branch backup-$(date +%s)`
- Use `git diff` and `git status` before any operation that modifies files

---

## Conventional Commits (Required)

Format: `<type>(<scope>): <subject>`
Example: `feat(auth): add OAuth2 login`

Types: `feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`

Rules: max 100 chars, lowercase, no period, squash merge PRs, feature branches from main

---

## Git MCP Tools (REQUIRED for Token Efficiency)

**ALWAYS use git plugin MCP tools instead of bash for reading:**

| Task           | Tool                 | Why                                  |
| -------------- | -------------------- | ------------------------------------ |
| Recent commits | `get_recent_commits` | Structured output, ~70% fewer tokens |
| Search history | `search_commits`     | Find by message or code changes      |
| Diff summary   | `get_diff_summary`   | Replaces `git diff --stat`           |

Tools prefixed: `mcp__plugin_git_git-intelligence__`

**For writes** (commits, branches, pushes): Use bash or `/git:*` slash commands.

---

## Homebrew Workflow

1. **Install**: `brew install <package>`
2. **Record**: Add to `~/.config/brew/Brewfile`
3. **Sync**: `brew bundle --file=~/.config/brew/Brewfile`
