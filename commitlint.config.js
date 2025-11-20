/**
 * Commitlint Configuration
 * Enforces Conventional Commits format
 *
 * Format: <type>(<scope>): <subject>
 *
 * Types:
 *   feat     - A new feature
 *   fix      - A bug fix
 *   chore    - Maintenance, dependencies, build changes
 *   docs     - Documentation changes
 *   refactor - Code refactoring without feature/bug changes
 *   perf     - Performance improvements
 *   test     - Adding or updating tests
 *   style    - Code style changes (formatting, missing semicolons, etc)
 *   ci       - CI/CD configuration changes
 *
 * Example:
 *   feat(vault): add auto-registration for project vaults
 *   fix(tmux): resolve window naming conflicts in parallel sessions
 *   chore(deps): update pnpm lock file
 */

module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "type-enum": [
      2,
      "always",
      ["feat", "fix", "chore", "docs", "refactor", "perf", "test", "style", "ci", "build"],
    ],
    "type-case": [2, "always", "lowercase"],
    "type-empty": [2, "never"],
    "scope-case": [2, "always", "lowercase"],
    "subject-case": [2, "never", ["start-case", "pascal-case", "upper-case"]],
    "subject-empty": [2, "never"],
    "subject-full-stop": [2, "never", "."],
    "header-max-length": [2, "always", 100],
    "body-leading-blank": [2, "always"],
    "body-max-line-length": [2, "always", 100],
    "footer-leading-blank": [2, "always"],
  },
};
