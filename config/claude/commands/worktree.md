# 🌳 Create Git Worktree for Next Available Todo

You are to create a new git worktree in a peer directory for the first available todo item (not completed and not already in progress).

## Todo Status Icons:
- `[ ]` - Not started
- `[x]` - Completed
- `[>]` - In progress in a peer directory/worktree

## Steps to follow:

1. **Find the next available todo**:
  - Read the file `./.llm/todo.md`. The file will only exist in this directory. Don't look in other locations. Don't look in the home directory.
  - Look for the first todo that is marked with `[ ]` (not `[x]` or `[>]`)
  - This will be the todo to work on
  - If no available todos exist, inform the user that all todos are either completed or in progress

2. **Update the todo status**:
   - Change the selected todo from `[ ]` to `[>]` in the original todo list
   - Add a comment indicating which worktree it's being worked on in, e.g.:
     ```markdown
     - [>] Implement user authentication with JWT <!-- worktree: implement-user-auth-jwt -->
     ```

3. **Create the git worktree**:
   - Determine the current repository's root directory
   - Create a worktree name based on the todo item (use kebab-case)
   - Create the worktree in a peer directory: `git worktree add ../<worktree-name> -b <branch-name> ${UPSTREAM_REMOTE:-origin}/${UPSTREAM_BRANCH:-main}`
     - `<worktree-name>` and `<branch-name>` are placeholders for you to replace with names of your choice
     - `UPSTREAM_REMOTE` and `UPSTREAM_BRANCH` are real environment variables
   - The `<branch-name>` should be prefixed with `task/`
   - The `<worktree-name>` should start with the original repository's directory name

4. **Set up the todo file in the new worktree**:
   - If there is a `.envrc` file in this directory, copy it into the new directory and run `direnv allow ../<worktree-name>`
   - Run `mise trust ../<worktree-name>`
   - Create the directory `.llm` if it doesn't exist
   - Create `.llm/todo.md` with ONLY this single todo item:

```markdown
# Todo

- [ ] [Single todo item text here]
  - [Other context that was under the original todo]

When this task is complete:
- Edit the original task list at `<this directory>/.llm/todo.md`, on line <line>
- Update the todo status from `[>]` to `[x]`
```
