---
paths:
  - "bin/**/*.sh"
  - "apps/**/*.sh"
  - "config/**/*.sh"
---

# Shell Script Code Style

## Script Structure

```bash
#!/usr/bin/env bash
# Purpose: Brief description of what this script does

set -e  # Exit on error (required)
set -u  # Exit on undefined variable (recommended)

# Source utilities
source "$(dirname "${BASH_SOURCE[0]}")/../utils/colour_log.sh"

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${HOME}/.config/example"

# Functions
function cleanup() {
  log_info "Cleaning up..."
}

function main() {
  trap cleanup EXIT
  # Main logic here
}

# Execute
main "$@"
```

## Conventions

**Error Handling:**
- Always use `set -e` for fail-fast behavior
- Use `trap cleanup EXIT` for resource cleanup
- Check command existence: `command -v tool >/dev/null 2>&1 || log_error "tool not found"`
- Provide context: `log_error "Failed to symlink ${source} → ${target}"`

**Variables:**
- Quote all expansions: `"${var}"` not `$var`
- Use `local` in functions: `local result="${1}"`
- Constants: `readonly UPPER_SNAKE_CASE`
- Prefer `[[` over `[`: `if [[ -f "${file}" ]]; then`

**Naming:**
- Scripts: `snake_case.sh` (e.g., `symlinks_manage.sh`)
- Functions: `snake_case` (e.g., `check_requirements`)
- No camelCase in bash

**Logging:**
- Use colour_log utilities: `log_error`, `log_warning`, `log_success`, `log_info`
- Include context in messages: `log_success "Installed ${package}"`

## TypeScript/JavaScript (Raycast)

**Style:**
- No semicolons
- Single quotes
- 2-space indentation
- Trailing commas

**Imports:**
```typescript
// External dependencies
import { showToast, Toast } from '@raycast/api'

// Internal modules
import { parseJSON } from './utils'

// Types
import type { Config } from './types'
```
