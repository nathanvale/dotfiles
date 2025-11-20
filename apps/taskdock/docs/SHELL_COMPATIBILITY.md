# TaskDock Shell Compatibility

TaskDock is designed to work with **Bash 4.0+** across different platforms.

## Supported Shells

### ✅ Fully Supported

- **Bash 4.0+** (Linux, macOS, WSL)
  - Primary target
  - All features tested and supported
  - Recommended version: 4.3+

### ⚠️ Not Supported

- **sh/POSIX shell** - Uses bash-specific features
- **zsh** - Would need modifications
- **fish** - Would need complete rewrite
- **dash** - Missing required bash features

## Platform Support

### Linux
- ✅ **Ubuntu 18.04+**: Bash 4.4+ (native)
- ✅ **Debian 10+**: Bash 5.0+ (native)
- ✅ **RHEL/CentOS 7+**: Bash 4.2+ (native)
- ✅ **Fedora**: Bash 5.0+ (native)
- ✅ **Arch**: Bash 5.0+ (native)

### macOS
- ✅ **macOS 10.13+**: Bash 3.2 (built-in) - **Limited**
- ✅ **macOS with Homebrew**: Bash 5.0+ (recommended)

**Installation:**
```bash
brew install bash
# Add to /etc/shells
echo /usr/local/bin/bash | sudo tee -a /etc/shells
# Change default shell
chsh -s /usr/local/bin/bash
```

### Windows
- ✅ **WSL (Ubuntu)**: Bash 5.0+ (native)
- ✅ **WSL (Debian)**: Bash 5.0+ (native)
- ✅ **Git Bash**: Bash 4.4+ (works with limitations)
- ❌ **PowerShell**: Not supported
- ❌ **CMD**: Not supported

## Bash-Specific Features Used

TaskDock uses the following bash-specific features that are NOT POSIX-compatible:

### 1. Arrays
```bash
# Used extensively for task lists, arguments, etc.
local tasks=()
tasks+=("item1" "item2")
```

### 2. `[[` Test Operator
```bash
# More powerful than [ ]
if [[ "$var" == "value" ]]; then
  # ...
fi
```

### 3. `$()` Command Substitution
```bash
# POSIX but preferred over backticks
result=$(command)
```

### 4. `local` Variables
```bash
# Function-local scope
local var="value"
```

### 5. `set -euo pipefail`
```bash
# Strict error handling
# -e: exit on error
# -u: error on undefined variable
# -o pipefail: pipeline fails if any command fails
```

### 6. Process Substitution
```bash
# Used for reading command output
while read -r line; do
  # ...
done < <(command)
```

### 7. `${var:-default}` Parameter Expansion
```bash
# Default values
value="${VAR:-default}"
```

### 8. `${var//pattern/replacement}` String Manipulation
```bash
# String replacement
cleaned="${str//search/replace}"
```

### 9. `printf` with `-v` flag
```bash
# Assign to variable (bash 3.1+)
printf -v formatted "%04d" "$number"
```

### 10. File Descriptor Management
```bash
# Used in flock implementation
exec {fd}>"$file"
```

## Compatibility Verification

### Check Bash Version

```bash
# Get bash version
bash --version

# Check if bash 4.0+
if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
  echo "Compatible"
else
  echo "Upgrade bash to 4.0+"
fi
```

### Feature Detection

TaskDock includes runtime checks for critical features:

```bash
# Check for required commands
command -v jq >/dev/null || {
  echo "jq is required"
  exit 1
}

# Check for flock support
if command -v flock >/dev/null; then
  echo "flock available"
else
  echo "flock not available (required for concurrency)"
fi
```

## Known Platform Differences

### macOS vs Linux

#### 1. `date` Command
```bash
# macOS uses BSD date
date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" +%s

# Linux uses GNU date
date -u -d "$timestamp" +%s

# TaskDock handles both
```

#### 2. `sed` Command
```bash
# macOS requires -i '' for in-place editing
sed -i '' 's/old/new/' file

# Linux can use -i directly
sed -i 's/old/new/' file

# TaskDock uses portable syntax
```

#### 3. `readlink` Command
```bash
# macOS doesn't have readlink -f
# TaskDock uses alternative methods
realpath=$(cd "$(dirname "$file")" && pwd)
```

#### 4. `flock` Command
```bash
# Linux: /usr/bin/flock (util-linux)
# macOS: Not included by default

# Install on macOS:
brew install flock
```

### Git Bash (Windows) Limitations

1. **Slow file operations**: Windows filesystem is slower
2. **Path conversions**: Windows paths need special handling
3. **Symlinks**: Limited symlink support
4. **Case sensitivity**: NTFS is case-insensitive by default

## Shellcheck Integration

TaskDock includes shellcheck integration for code quality:

### Run Shellcheck

```bash
# Check all scripts
./taskdock/scripts/shellcheck-all.sh

# Check specific file
shellcheck taskdock/lib/common.sh
```

### Shellcheck Configuration

Disabled warnings:
- `SC1090`: Can't follow non-constant source (expected)
- `SC1091`: Not following sourced files (expected)
- `SC2034`: Variable appears unused (many are exported)

### CI Integration

```bash
# Add to CI pipeline
- name: Shellcheck
  run: |
    shellcheck --version
    ./taskdock/scripts/shellcheck-all.sh
```

## Porting Guide

If you need to port TaskDock to another shell:

### To POSIX sh

**Challenges:**
1. Replace all arrays with space-delimited strings
2. Replace `[[` with `[`
3. Remove process substitution
4. Replace `local` with function-scope tricks
5. Rewrite file descriptor management

**Effort:** High (2-3 weeks)

### To zsh

**Challenges:**
1. Array indices start at 1 (vs 0 in bash)
2. Some string operations differ
3. Parameter expansion differences

**Effort:** Medium (1 week)

### To fish

**Challenges:**
1. Completely different syntax
2. No compatibility with bash
3. Would need full rewrite

**Effort:** Very High (1 month+)

## Testing Matrix

TaskDock should be tested on:

| Platform | Shell | Version | Status |
|----------|-------|---------|--------|
| Ubuntu 22.04 | bash | 5.1.16 | ✅ Tested |
| Ubuntu 20.04 | bash | 5.0.17 | ✅ Tested |
| macOS 13 (Ventura) | bash | 3.2.57 | ⚠️ Limited |
| macOS 13 + Homebrew | bash | 5.2.15 | ✅ Tested |
| macOS 14 (Sonoma) | bash | 3.2.57 | ⚠️ Limited |
| macOS 14 + Homebrew | bash | 5.2.21 | ✅ Tested |
| WSL Ubuntu | bash | 5.1.16 | ✅ Tested |
| Git Bash (Windows) | bash | 4.4.23 | ⚠️ Works |

## Requirements Documentation

### Minimum Requirements

```yaml
shell:
  name: bash
  version: "4.0"
  recommended: "5.0+"

platform:
  linux: "Any modern distribution"
  macos: "10.13+ with Homebrew bash"
  windows: "WSL recommended, Git Bash works"

dependencies:
  required:
    - git: "2.25+"
    - jq: "1.5+"
    - flock: "2.x" (Linux native, brew on macOS)
  optional:
    - yq: "4.x" (YAML config parsing)
    - gh: "2.x" (GitHub PR operations)
    - az: "2.x" (Azure DevOps operations)
```

### Installation Instructions

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y bash jq git flock
```

**macOS:**
```bash
brew install bash jq git flock yq gh
```

**RHEL/CentOS:**
```bash
sudo yum install -y bash jq git util-linux
```

**Arch:**
```bash
sudo pacman -S bash jq git util-linux
```

## Best Practices for Contributors

### 1. Use Bash Shebang
```bash
#!/usr/bin/env bash
# NOT #!/bin/sh or #!/bin/bash
```

### 2. Use Strict Mode
```bash
set -euo pipefail
```

### 3. Use `[[` for Tests
```bash
# Good
if [[ "$var" == "value" ]]; then

# Avoid
if [ "$var" = "value" ]; then
```

### 4. Quote Variables
```bash
# Good
echo "$var"
"$command" "$arg"

# Bad
echo $var
$command $arg
```

### 5. Use Arrays for Lists
```bash
# Good
items=("one" "two" "three")
for item in "${items[@]}"; do
  echo "$item"
done

# Avoid
items="one two three"
for item in $items; do
  echo "$item"
done
```

### 6. Use `$()` Over Backticks
```bash
# Good
result=$(command)

# Avoid
result=`command`
```

### 7. Check Command Existence
```bash
# Good
if command -v jq >/dev/null; then
  # use jq
fi

# Avoid
if which jq; then
  # use jq
fi
```

### 8. Handle Errors
```bash
# Good
if ! command; then
  error "Command failed"
  exit 1
fi

# Or with explicit check
command || {
  error "Command failed"
  exit 1
}
```

## Linting Configuration

### `.shellcheckrc` (Recommended)

Create in project root:
```bash
# TaskDock Shellcheck Config

# Disable non-constant source warnings
disable=SC1090
disable=SC1091

# Disable unused variable warnings (we export many)
disable=SC2034

# Shell is bash
shell=bash

# Severity level
severity=style
```

### VS Code Integration

Install ShellCheck extension:
```json
{
  "shellcheck.enable": true,
  "shellcheck.run": "onSave",
  "shellcheck.exclude": ["1090", "1091", "2034"]
}
```

## Troubleshooting

### "Bad substitution" Error
**Cause:** Using bash syntax in sh/dash  
**Fix:** Ensure shebang is `#!/usr/bin/env bash`

### "command not found: [["
**Cause:** Script running in sh instead of bash  
**Fix:** Check shebang, make script executable

### "array: not found"
**Cause:** Arrays not supported in sh  
**Fix:** Use bash, not sh

### flock: command not found (macOS)
**Cause:** flock not installed  
**Fix:** `brew install flock`

### Slow performance on Windows
**Cause:** Git Bash/Windows filesystem overhead  
**Fix:** Use WSL for better performance

## Future Improvements

- [ ] Add automatic bash version detection in `taskdock doctor`
- [ ] Create compatibility shim for bash 3.2 (macOS default)
- [ ] Add CI testing matrix for multiple bash versions
- [ ] Consider POSIX-compatible fallbacks for critical operations
- [ ] Add performance benchmarks across platforms

---

**Last Updated:** 2025-11-19  
**TaskDock Version:** 0.1.0+shell-compat
