# CLI Script Templates

Starter templates for ADHD-friendly CLI tools following Google Shell Style Guide best practices.

## Quick Start

```bash
# Copy template
cp bin/templates/cli-template.sh bin/my-tool

# Edit and customize
code bin/my-tool
```

## Template Features

| Feature | Description |
|---------|-------------|
| `set -euo pipefail` | Fail-fast on errors, unset vars, pipe failures |
| NO_COLOR support | Respects accessibility standards |
| Subcommand router | Clean `cmd_*` function pattern |
| Google-style docs | `#######` function headers |
| Source-safe | Won't run main when sourced |

## Adding Commands

1. Create function with `cmd_` prefix:
```bash
cmd_mycommand() {
  local arg="${1:-default}"
  # implementation
}
```

2. Add to router in `main()`:
```bash
case "${cmd}" in
  mycommand) cmd_mycommand "$@" ;;
  # ...
esac
```

3. Document in `cmd_help()`:
```bash
${GREEN}mycommand [arg]${RESET}  Description here
```

## Patterns

### Safe File Iteration (avoid subshell variable loss)

```bash
# BAD - counter lost in subshell
find ... | while read -r f; do ((count++)); done

# GOOD - process substitution
while read -r f; do ((count++)); done < <(find ...)
```

### Require Dependencies

```bash
require_command jq
require_command fzf
```

### Optional Flags with Defaults

```bash
local verbose="${verbose:-false}"
local limit="${1:-10}"
```

## Style Rules

- 2-space indentation
- `"${var}"` over `$var`
- `[[ ]]` over `[ ]`
- Functions before `main()`
- Constants at top (UPPERCASE)
- Local vars in functions (lowercase)
