# Nathan's Claude Code Preferences

## About Me

- **Location**: Melbourne, Australia (AEST/AEDT)
- **ADHD** - Cognitive load is my enemy. DX matters enormously.
- **Visual learner** - Clear structure, whitespace, and formatting help me process.
- **Exploratory mindset** - I want to learn from what you do. Explain the "why."
- **Morning person** - Up early, start coding immediately. Get tired early evenings.

### Important People
- **Melanie** - Partner (also "Bestie" or "Sweetheart")
- **Levi** - Son (age 9), Nathan is sole parent
- **Mum** - Lives in Sydney

For birthdays, hobbies, and other personal details: `~/.claude/context/personal.md`

### Second Brain (Obsidian + PARA)
Obsidian vault stores all project and personal context using PARA method.
Use `/para-brain:*` commands. Full setup: `~/.claude/context/obsidian-setup.md`

### SideQuest Marketplace
ADHD-focused plugins at `~/code/side-quest-marketplace/`
**If a plugin isn't installed, ask if I want to install it.**

Essential: `git`, `para-brain`, `claude-code-docs`, `atuin`, `bun-runner`, `claude-code-claude-md`

### Reference Context
`~/.claude/context/`: `personal.md`, `personal-projects.md`, `learning-goals.md`, `obsidian-setup.md`

---

## Critical Rules

### Never Do These
- **NEVER delete or remove untracked git changes** - This is catastrophic
- **NEVER start implementing without confirmation** - Always present plan first
- **NEVER refactor without asking** - Propose changes, wait for approval
- **NEVER use destructive git commands** - No `reset --hard`, `push --force`, `clean -fd`

### Always Do These
- **Read code before proposing changes** - Understand context first
- **Plan → Confirm → Execute → Test** - Every time
- **Chunk work into small pieces** - Helps me follow along
- **Use visual formatting** - Headers, bullets, code blocks, whitespace

---

## Communication Style

- Technical and concise
- Explain decisions (the "why" not just "what")
- No emojis unless I ask
- Use clear visual structure in responses
- Break complex info into digestible chunks

---

## Code Philosophy

### Patterns I Love
- **Functional programming** - Pure functions, immutability, composition
- **Factory patterns** - For object creation
- **Dependency injection** - For testability and flexibility
- **Small, focused modules** - Single responsibility
- **Abstraction is good** - I prefer well-structured over "simple but messy"

### Code Style
- TypeScript strict mode always
- 2-space indentation
- `kebab-case` lowercase for file names
- No abbreviated variable names
- Keep functions simple (refactor complex ones)

### Documentation
- **Lots of JSDoc comments** - TypeDoc compatible
- Document the "why" in comments
- Every exported function needs JSDoc

```typescript
/**
 * Creates a user repository with dependency injection.
 * @param db - Database client instance
 * @returns User repository with CRUD operations
 */
export function createUserRepository(db: Database): UserRepository {
  // ...
}
```

---

## Tech Stack

| Tool | Version/Notes |
|------|---------------|
| Bun | Primary package manager |
| Node | 22+ |
| TypeScript | Strict mode |
| React | Functional components |
| Tailwind | For styling |
| Biome | Linting and formatting |

---

## Testing

- **TDD for big features** - Write tests first
- **Ask about TDD for small features/fixes** - I'll decide case-by-case
- Coverage goal: 80%
- Prefer integration tests over unit tests for behavior

---

## Git Workflow

### Conventional Commits (Required)
```
<type>(<scope>): <subject>

Example: feat(auth): add OAuth2 login support
```

| Type | Purpose |
|------|---------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation |
| style | Formatting |
| refactor | Code refactoring |
| perf | Performance |
| test | Tests |
| build | Build system changes |
| ci | CI/CD changes |
| chore | Maintenance tasks |
| revert | Revert changes |

### Rules
- Header max 100 characters
- Lowercase type and scope
- No period at end of subject
- Squash merge PRs
- Feature branches from main

---

## Workflow Preferences

1. **Read** relevant files first
2. **Plan** using think mode for complex tasks
3. **Confirm** with me before implementing
4. **Execute** incrementally in small chunks
5. **Test** and verify each step
6. **Explain** what you did and why
