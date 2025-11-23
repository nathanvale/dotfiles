/**
 * Commitlint Configuration
 * Enforces Gitmoji + Conventional Commits format
 *
 * Format: <emoji> <type>(<scope>): <subject>
 *
 * Types (with emoji):
 *   🎉 init     - Begin a project
 *   ✨ feat     - A new feature
 *   🐞 fix      - A bug fix
 *   📃 docs     - Documentation changes
 *   🌈 style    - Code style changes (formatting, etc)
 *   🦄 refactor - Code refactoring
 *   🎈 perf     - Performance improvements
 *   🧪 test     - Adding or updating tests
 *   🔧 build    - Build system changes
 *   🐎 ci       - CI/CD configuration changes
 *   🐳 chore    - Maintenance tasks
 *   ↩ revert    - Revert changes
 *
 * Example:
 *   ✨ feat(vault): add auto-registration for project vaults
 *   🐞 fix(tmux): resolve window naming conflicts in parallel sessions
 *   🐳 chore(deps): update pnpm lock file
 */

module.exports = {
  extends: ['git-commit-emoji'],
  rules: {
    'header-max-length': [2, 'always', 100],
    'body-leading-blank': [2, 'always'],
    'body-max-line-length': [2, 'always', 100],
    'footer-leading-blank': [2, 'always'],
  },
};
