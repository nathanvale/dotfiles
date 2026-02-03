# Chezmoi Migration Evaluation

**Goal:** Determine if migrating from shell-based dotfiles to Chezmoi is worth the effort.

## What Chezmoi Offers

| Feature | Current Approach | Chezmoi |
|---------|------------------|---------|
| **Templating** | Shell scripts with conditionals | Native Go templates (`{{ if eq .chezmoi.hostname "server" }}`) |
| **Secrets** | Manual `.env` files | 1Password, Bitwarden, pass integration |
| **Multi-machine** | `DOTFILES_PROFILE` env var | Auto-detects OS, hostname, arch |
| **Symlinks** | Custom `symlinks_manage.sh` | Built-in `symlink_` prefix |
| **Encrypted files** | Not supported | Built-in with age/gpg |
| **One-liner install** | `curl | bash -s -- --server` | `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply user` |

## What You'd Gain

### 1. Native Templating
Instead of separate logic in shell scripts:
```bash
# Current: bootstrap.sh
if [[ "$profile" == "server" ]]; then
    ./config/macos/defaults.server.sh
fi
```

Chezmoi templates inline:
```
{{- if eq .profile "server" }}
# Server-specific zshrc content
export OLLAMA_KEEP_ALIVE=24h
{{- end }}
```

### 2. 1Password Secrets Integration
Current: Manual `.env` files, copy secrets by hand

Chezmoi:
```toml
# ~/.config/chezmoi/chezmoi.toml
[onepassword]
command = "op"

[data]
github_token = {{ onepasswordRead "op://Personal/GitHub Token/credential" }}
```

Then in templates:
```
export GITHUB_TOKEN={{ .github_token }}
```

### 3. Automatic Machine Detection
No need for `--server` / `--desktop` flags:
```
{{- if eq .chezmoi.hostname "mac-mini-server" }}
# Server config
{{- else }}
# Desktop config
{{- end }}
```

Or use custom data in `chezmoi.toml`:
```toml
[data]
profile = "server"  # Set once per machine
```

### 4. Encrypted Files
Store secrets in repo safely:
```bash
chezmoi add --encrypt ~/.ssh/id_ed25519
# Creates encrypted file, decrypted on apply
```

## What You'd Lose / Effort Required

### 1. Learning Curve
- Go template syntax (not hard, but different)
- Chezmoi's file naming conventions (`dot_`, `run_`, `modify_`)
- New mental model for source state vs target state

### 2. Migration Effort
- Convert all dotfiles to chezmoi format
- Rewrite shell conditionals as templates
- Set up 1Password integration
- Test on both desktop and server

### 3. Bootstrap Complexity
Your 7-phase bootstrap with checkpoint/resume is custom. Chezmoi's bootstrap is simpler but less controllable:
- Chezmoi runs scripts in alphabetical order
- No built-in checkpoint/resume
- Would need to keep some shell scripts alongside

### 4. Brewfile Handling
Chezmoi doesn't manage Brewfiles directly. Options:
- Keep Brewfile separate (run `brew bundle` from a `run_` script)
- Use Chezmoi templates for Brewfile itself

## Recommendation

**Don't migrate now.** Here's why:

1. **Your current setup works** - Profile selection, Brewfile conditionals, server defaults all function correctly.

2. **Main gains are marginal for your use case:**
   - Templating: Your shell conditionals are fine for 2 profiles
   - 1Password: Nice-to-have but not blocking
   - Multi-machine: You only have 2 machines with explicit profiles

3. **Better investment of time:**
   - Test current implementation in VM
   - Deploy to Mac Mini
   - Iterate based on real usage

4. **Revisit Chezmoi if:**
   - You add more machines (3+)
   - Secrets management becomes painful
   - You need encrypted dotfiles in repo
   - You want to share dotfiles publicly but keep secrets private

## If You Do Migrate Later

### Quick Start
```bash
# Install chezmoi
brew install chezmoi

# Initialize from existing dotfiles
chezmoi init

# Add files
chezmoi add ~/.zshrc
chezmoi add ~/.gitconfig

# Edit with templates
chezmoi edit ~/.zshrc  # Opens source file

# Apply changes
chezmoi apply
```

### Migration Path
1. Start fresh chezmoi repo alongside existing dotfiles
2. Migrate files one at a time, testing each
3. Add templating for profile differences
4. Set up 1Password integration
5. Test on both machines
6. Archive old dotfiles repo

### Resources
- [chezmoi.io](https://www.chezmoi.io/) - Official docs
- [Quick Start](https://www.chezmoi.io/quick-start/)
- [Manage Machine Differences](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [1Password Integration](https://www.chezmoi.io/user-guide/password-managers/1password/)
