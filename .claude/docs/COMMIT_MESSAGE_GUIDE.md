# Commit Message Guide

## Overview

This project uses **Conventional Commits** with **commitlint** to enforce consistent, standardized commit messages. This ensures:

- Clear project history
- Automated changelog generation
- Better code review context
- Team communication standards

## The Standard Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Type (Required)

Use one of these types:

| Type | Description | Example |
| ---- | ----------- | ------- |
| `feat` | New feature | `feat(vault): add auto-registration` |
| `fix` | Bug fix | `fix(tmux): resolve window naming conflicts` |
| `chore` | Maintenance, dependencies, build | `chore(deps): update pnpm lock file` |
| `docs` | Documentation changes | `docs: update README with setup guide` |
| `refactor` | Code restructuring (no feature/bug change) | `refactor(scripts): simplify error handling` |
| `perf` | Performance improvements | `perf(startup): reduce shell init time` |
| `test` | Test additions/updates | `test: add unit tests for config validator` |
| `style` | Code formatting, semicolons, etc. | `style: format bash scripts with shfmt` |
| `ci` | CI/CD configuration changes | `ci: add GitHub Actions workflow` |
| `build` | Build system changes | `build: update Brewfile dependencies` |

## Scope (Optional)

The scope specifies **what area of the code** is affected. In this project, common scopes include:

- `prettier` - Formatting/prettier configuration
- `vault` - Vault management system
- `tmux` - Tmux configuration and scripts
- `hyperflow` - HyperFlow keyboard orchestration
- `taskdock` - TaskDock CLI system
- `deps` - Dependencies and package management
- `config` - Configuration files
- `scripts` - Shell scripts and utilities

## Subject (Required)

Guidelines:
- ✅ **Start with lowercase** (except proper nouns)
- ✅ **Imperative mood**: "add feature" not "added feature"
- ✅ **No period** at the end
- ✅ **Under 100 characters** (including type, scope, colon, space)
- ✅ **Specific and descriptive**

### ✅ Good Examples
```
feat(vault): add auto-registration for project vaults
fix(tmux): resolve window naming conflicts in parallel sessions
chore(deps): update pnpm to 10.22.0
docs(claude): add commit message guide
refactor(config): consolidate shell configuration files
perf(startup): reduce dotfiles initialization time by 40%
```

### ❌ Bad Examples
```
feat(vault): Added auto-registration for project vaults  ← past tense
feat(vault): Add auto registration for project vaults in the system → too long
feat(vault): Add auto-registration for project vaults.  ← has period
FIX: resolve window naming conflicts  ← uppercase, no scope
update files  ← vague, no type
```

## Body (Optional, but recommended for complex changes)

Use the body to explain **why** the change was made, not **what** was changed (the diff shows that).

Guidelines:
- **Blank line** before body (always)
- **Line wrap at 100 characters**
- **Explain motivation and context**
- **Describe any breaking changes**
- **Reference related issues/PRs**

### Example with Body

```
fix(tmux): resolve window naming conflicts in parallel sessions

When running multiple agents in parallel, window names were being
overwritten due to race conditions in the tmux rename-window command.
Added mutex-based locking to prevent concurrent renames.

This fixes race conditions that occurred when 4+ agents were spawned
simultaneously in a single tmux session.

Closes #125
```

## Footer (Optional)

Use footers for:
- References to issues: `Closes #123`
- Breaking changes: `BREAKING CHANGE: ...`
- Co-authored commits: `Co-Authored-By: Name <email>`

### Example with Footer

```
feat(hyperflow): add SuperWhisper voice dictation modes

Add four new SuperWhisper modes for context-aware voice AI:
- engineering mode for code-specific vocabulary
- documentation mode for prose writing
- shell mode for terminal commands
- design mode for UI/UX terminology

Co-Authored-By: Claude <noreply@anthropic.com>
Closes #201
```

## Validation Rules

Commitlint automatically checks these rules (file: `commitlint.config.js`):

| Rule | Level | Check | Limit |
| ---- | ----- | ----- | ----- |
| `type-enum` | Error | Type must be in allowed list | See Type section |
| `type-case` | Error | Type must be lowercase | - |
| `type-empty` | Error | Type is required | - |
| `scope-case` | Error | Scope must be lowercase | - |
| `subject-case` | Error | Subject cannot be PascalCase or UPPERCASE | - |
| `subject-empty` | Error | Subject is required | - |
| `subject-full-stop` | Error | Subject cannot end with period | - |
| `header-max-length` | Error | Header line too long | 100 chars |
| `body-max-line-length` | Error | Body lines too long | 100 chars |
| `body-leading-blank` | Error | Missing blank line before body | - |
| `footer-leading-blank` | Error | Missing blank line before footer | - |

## How It Works

### Before Commit (Git Hook)

```
git commit -m "feat(vault): add auto-registration"
         ↓ (triggers .husky/commit-msg hook)
commitlint validates the message format
         ↓
If valid: commit succeeds ✅
If invalid: commit rejected with error message ❌
```

### Example: Validation Failure

```bash
$ git commit -m "Added feature to vault system"

⧗   input: Added feature to vault system
✖   type must be lowercase [type-case]
✖   type must be in enum [type-enum]
✖   type must not be empty [type-empty]

✖   found 3 problems, 0 warnings
```

## Pro Tips

### 1. Interactive Commit with Hook

Most editors will show the validation error when you save if the message is invalid:

```bash
git commit
# Opens editor → write message → save → commitlint validates
```

### 2. Amend and Fix

If you committed with a bad message:

```bash
git commit --amend
# Rewrite the message → commitlint validates again
```

### 3. Reference Issues

```bash
git commit -m "fix(tmux): resolve lock deadlock

Closes #123
Related-To: #120, #122"
```

### 4. Breaking Changes

```bash
git commit -m "refactor(config): restructure shell configuration

BREAKING CHANGE: ZSHRC_CUSTOM env var renamed to CUSTOM_SHELL_CONFIG"
```

## Common Mistakes

| Mistake | Problem | Fix |
| ------- | ------- | --- |
| `Feat: new feature` | Capitalized + space | `feat: new feature` |
| `feat new feature` | Missing scope and colon | `feat(scope): new feature` |
| `feat(SCOPE): feature` | Scope capitalized | `feat(scope): feature` |
| `feat: add feature here.` | Has period, use descriptive scope | `feat(vault): add feature here` |
| `feat: update everything` | Too vague | `feat(vault): add auto-registration` |
| Long subject over 100 chars | Too long | Break into subject + body |
| `feat: add feature` + body with no blank line | Missing blank line | Add blank line between subject and body |

## Linting Manually

To check commits without committing:

```bash
# Check last commit
pnpm commitlint --from HEAD~1 --to HEAD

# Check specific range
pnpm commitlint --from main --to feature-branch

# Check from beginning of branch
pnpm commitlint --from main..HEAD
```

## Configuration

The validation rules are defined in `commitlint.config.js`. To modify allowed types or limits, edit that file and restart your git hooks:

```bash
pnpm husky install
```

## Related Files

- `commitlint.config.js` - Validation rules
- `.husky/commit-msg` - Git hook that runs commitlint
- `package.json` - Lists commitlint dependencies
- `.prettierrc.json` - Formatting rules (complementary)

## References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [commitlint docs](https://github.com/conventional-changelog/commitlint)
- [Husky docs](https://typicode.github.io/husky/)
