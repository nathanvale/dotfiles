# ----------------------------------------------------------------------------
# PATH Setup (consolidated - order matters: later entries take priority)
# ----------------------------------------------------------------------------
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export PNPM_HOME="$HOME/.local/share/pnpm"
export BUN_INSTALL="$HOME/.bun"
export PATH="$PNPM_HOME/bin:$PATH"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

# Add dotfiles scripts to PATH
export PATH="$HOME/code/dotfiles/bin:$PATH"
export PATH="$HOME/code/dotfiles/bin/aerospace:$PATH"
export PATH="$HOME/code/dotfiles/bin/tmux:$PATH"
export PATH="$HOME/code/dotfiles/bin/vault:$PATH"
export PATH="$HOME/code/dotfiles/bin/utils:$PATH"
export PATH="$HOME/code/dotfiles/bin/env:$PATH"

# fnm default node (makes node/npm/npx available in non-interactive shells)
export PATH="$HOME/.local/share/fnm/aliases/default/bin:$PATH"

# Homebrew takes priority (must be last)
export PATH="/opt/homebrew/bin:$PATH"

# ----------------------------------------------------------------------------
# Environment Variables
# ----------------------------------------------------------------------------
export XDG_CONFIG_HOME="$HOME/.config"
export TERM=xterm-256color
export LANG="en_AU.UTF-8"
export LC_COLLATE="en_AU.UTF-8"
export LC_CTYPE="en_AU.UTF-8"

# Bat (better cat)
export PAGER="bat"
export BAT_THEME="Night Owl"

# Homebrew
export HOMEBREW_BUNDLE_FILE_GLOBAL="$HOME/.config/brew/Brewfile"
export HOMEBREW_BUNDLE_FILE="$HOME/.config/brew/Brewfile"

# CDPATH for quick navigation
export CDPATH=".:~:$HOME/code"

# ----------------------------------------------------------------------------
# Load Environment Variables
# ----------------------------------------------------------------------------
# Manual env vars (includes OP_SERVICE_ACCOUNT_TOKEN for 1Password)
if [ -f "$HOME/code/dotfiles/.env" ]; then
  source "$HOME/code/dotfiles/.env"
fi

# API keys (auto-generated from 1Password via sync-api-keys)
if [ -f "$HOME/code/dotfiles/.env.1password" ]; then
  source "$HOME/code/dotfiles/.env.1password"
fi

# ----------------------------------------------------------------------------
# FNM (Fast Node Manager) - Faster alternative to NVM
# ----------------------------------------------------------------------------
eval "$(fnm env --use-on-cd --shell zsh)"

# Ensure active node is in PATH for subprocesses (silences Bun's fnm warning)
export PATH="$(dirname "$(which node 2>/dev/null)"):$PATH" 2>/dev/null

# Strict mode: fail if .nvmrc exists but version not installed (ADHD-friendly)
export FNM_STRICT=true

# ----------------------------------------------------------------------------
# Prompt with Git Branch Support + Execution Time
# ----------------------------------------------------------------------------
autoload -Uz vcs_info
precmd() {
  local cmd_status=$?  # Capture exit status immediately
  # Git branch info
  vcs_info
  # Set terminal title to current directory name
  print -Pn "\e]0;%1~\a"

  # Execution time display (if command took >1 second)
  if [ $timer ]; then
    local timestamp=$(date +%s 2>/dev/null)
    if [[ "$timestamp" =~ ^[0-9]+$ ]]; then
      now=$(($timestamp * 1000))
      elapsed=$(($now-$timer))

      if [ $elapsed -gt 1000 ]; then
        local elapsed_seconds=$(printf "%.1f" $(echo "scale=1; $elapsed/1000" | bc))
        if [ $cmd_status -eq 0 ]; then
          echo -e "\033[0;32m✓ ${elapsed_seconds}s\033[0m"
        else
          echo -e "\033[0;31m✗ ${elapsed_seconds}s\033[0m"
        fi
      fi
    fi

    unset timer
  fi
}

# Configure vcs_info to show branch name
zstyle ':vcs_info:*' formats '%b'
zstyle ':vcs_info:*' actionformats '%b|%a'

setopt PROMPT_SUBST
# ADHD-friendly prompt with Node version indicator
PROMPT='%F{cyan}%1~%f %F{yellow}[$(node -v 2>/dev/null | sed "s/v//")]%f %F{green}${vcs_info_msg_0_}%f%(?.%(!.#.>).%(!.#.>)) '
RPS1=''  # Clear right prompt
PS2='> '

# ----------------------------------------------------------------------------
# History Configuration
# ----------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE      # Commands starting with space won't be saved

# ----------------------------------------------------------------------------
# Auto-completion (built-in, no plugins needed)
# ----------------------------------------------------------------------------
autoload -U compinit && compinit

# Load menuselect module for interactive menu
zmodload zsh/complist

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Enable interactive menu selection (like Oh My Zsh)
zstyle ':completion:*' menu select=2  # Show menu when 2+ matches
setopt AUTO_MENU                      # Show menu on second tab press
setopt COMPLETE_IN_WORD               # Complete from cursor position
setopt ALWAYS_TO_END                  # Move cursor to end after completion

# Highlight current selection in completion menu
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Completion menu navigation keybindings
bindkey -M menuselect '^[[Z' reverse-menu-complete  # Shift+Tab: go backwards
bindkey -M menuselect '^M' .accept-line             # Enter: accept selection
bindkey -M menuselect '^[' send-break               # Esc: cancel completion

# ----------------------------------------------------------------------------
# Directory Navigation (Better than Oh My Zsh!)
# ----------------------------------------------------------------------------
setopt AUTO_CD              # Just type directory name to cd
setopt AUTO_PUSHD          # Make cd push old dir onto dir stack
setopt PUSHD_IGNORE_DUPS   # Don't push duplicates
setopt PUSHD_SILENT        # Don't print dir stack after pushd/popd

# ----------------------------------------------------------------------------
# Aliases - Essential Tools
# ----------------------------------------------------------------------------

# Navigation
mkcd() { mkdir -p "$1" && cd "$1"; }
alias take='mkcd'
d() { cd ~/code; }          # Quick jump to code directory (overrides Oh My Zsh)
alias de="cd ~/Desktop"

# ADHD-friendly: Clear version switching feedback
cd() {
  local prev_node=$(node -v 2>/dev/null)
  builtin cd "$@"
  local new_node=$(node -v 2>/dev/null)
  if [[ "$prev_node" != "$new_node" && -n "$new_node" ]]; then
    echo "🔄 Switched Node: $prev_node → $new_node"
  fi
}
alias c="code ."
alias ca="code . ~/code/dotfiles/config/aerospace/aerospace.toml"

# Task management
alias locks="~/.claude/scripts/list-task-locks.sh"
alias unlock="~/.claude/scripts/unlock-task.sh"

# Modern replacements
alias ls="eza --color=always --icons"
alias ll="eza -l --color=always --icons"
alias lla="eza -l -a --color=always --icons"
alias la="eza -a --color=always --icons"
alias lt="eza --tree --color=always --icons"
# Smart cat: use bat for terminal, real cat for pipes
# Must unalias first before defining function
unalias cat 2>/dev/null
cat() {
  # If no arguments and stdin is a terminal, show usage hint
  if [[ $# -eq 0 && -t 0 ]]; then
    echo "Usage: cat <file>... (waiting for stdin, Ctrl+D to end, Ctrl+C to cancel)" >&2
    command cat "$@"
    return
  fi

  if [[ -t 1 ]]; then
    # Check if any file is binary
    local has_binary=0
    for file in "$@"; do
      if [[ -f "$file" ]] && ! file -b --mime "$file" | grep -q "^text/"; then
        has_binary=1
        break
      fi
    done

    if [[ $has_binary -eq 1 ]]; then
      # Binary file detected - use regular cat
      command cat "$@"
    else
      # Text file - use bat for pretty display
      command bat --paging=never --style=plain "$@"
    fi
  else
    # Output is piped - use real cat (no line numbers!)
    command cat "$@"
  fi
}
alias batn="bat -n"
alias less="bat"
alias mv="gmv"

# Git
alias lz="lazygit"
alias gs="git status"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias ga="git add"
alias gc="git commit"

# GitHub CLI - account switching
alias ghpersonal='gh auth switch -u nathanvale'

# Utilities
alias pg="echo 'Pinging Google' && ping www.google.com"
ports() { lsof -i :"$1"; }  # See what's running on a port

# Claude Code
alias cc="claude --dangerously-skip-permissions"
# ccdev function - disables corepack/pnpm package manager detection to avoid
# "This project is configured to use yarn" errors when starting in non-pnpm projects
function ccdev() {
  COREPACK_ENABLE_STRICT=0 claude --dangerously-skip-permissions \
    --plugin-dir ~/code/side-quest-plugins/plugins/agent-skills-bridge \
    --plugin-dir ~/code/side-quest-marketplace/plugins/atuin \
    --plugin-dir ~/code/side-quest-plugins/plugins/biome-runner \
    --plugin-dir ~/code/side-quest-marketplace/plugins/bookmarks \
    --plugin-dir ~/code/side-quest-plugins/plugins/bun-runner \
    --plugin-dir ~/code/side-quest-plugins/plugins/bun-starter \
    --plugin-dir ~/code/side-quest-marketplace/plugins/claude-code-claude-md \
    --plugin-dir ~/code/side-quest-marketplace/plugins/claude-code-docs \
    --plugin-dir ~/code/side-quest-marketplace/plugins/claude-code-skill-expert \
    --plugin-dir ~/code/side-quest-marketplace/plugins/clipboard \
    --plugin-dir ~/code/side-quest-marketplace/plugins/dev-toolkit \
    --plugin-dir ~/code/side-quest-marketplace/plugins/firecrawl \
    --plugin-dir ~/code/side-quest-marketplace/plugins/git \
    --plugin-dir ~/code/side-quest-marketplace/plugins/kit \
    --plugin-dir ~/code/side-quest-plugins/plugins/macos-settings \
    --plugin-dir ~/code/side-quest-marketplace/plugins/mcp-manager \
    --plugin-dir ~/code/side-quest-marketplace/plugins/para-obsidian \
    --plugin-dir ~/code/side-quest-marketplace/plugins/plugin-template \
    --plugin-dir ~/code/side-quest-marketplace/plugins/scraper-toolkit \
    --plugin-dir ~/code/side-quest-marketplace/plugins/teams-scrape \
    --plugin-dir ~/code/side-quest-marketplace/plugins/terminal \
    --plugin-dir ~/code/side-quest-marketplace/plugins/the-cinema-bandit \
    --plugin-dir ~/code/side-quest-plugins/plugins/tsc-runner \
    --plugin-dir ~/code/side-quest-plugins/plugins/utm-testing \
    --plugin-dir ~/code/side-quest-marketplace/plugins/validate-plugin \
    --plugin-dir ~/code/side-quest-plugins/plugins/x-api \
    "$@"
}
alias cct="npx @mariozechner/claude-trace"
alias ccu="npx ccusage@latest"
alias ccs="npx @mariozechner/snap-happy to local"
alias ccd="c ~/Library/Application\ Support/Claude/claude_desktop_config.json"
alias ccr="claude --dangerously-skip-permissions -r"
alias cleanpaste='pbpaste | sed "s/^[[:space:]]*//" | pbcopy'  # Fix Claude Code copy-paste whitespace
alias claude-mcp="bun run ~/code/side-quest-marketplace/plugins/mcp-manager/src/cli.ts"

# Para-Obsidian Inbox Processor (AI-powered inbox processing)
alias inbox="bun run ~/code/side-quest-marketplace/plugins/para-obsidian/src/cli.ts process-inbox"

# Codex (YOLO mode)
alias cx="codex --dangerously-bypass-approvals-and-sandbox"

# Aerospace (window manager)
alias sa="aerospace reload-config"
alias aero-help="~/code/dotfiles/bin/aerospace/help.sh"
alias aero-keys="~/code/dotfiles/bin/aerospace/hud.sh --notify"
alias aero="aerospace"
alias meeting="aerospace workspace M && aerospace close-all-windows-but-current && aerospace fullscreen"
alias teams-meeting="meeting"

# Shell config
alias cz="code ~/.zshrc"
alias sz="source ~/.zshrc"

# Morning routine for ADHD brain
morning() {
  echo "☕ Good morning, Nathan!"
  echo "Node versions installed:"
  fnm list  # See what you have
  echo "---"
  echo "Recent projects:"
  eza -l --sort=modified --reverse ~/code | head -5
}

# Projects
alias p.dotfiles="cd ~/code/dotfiles/ && code ."

# Node
alias w.nvmrc="node -v > .nvmrc"
alias node-lock="node -v > .nvmrc && echo '📌 Locked to $(node -v)'"
alias nv="echo 'Node: $(node -v) | npm: $(npm -v) | pnpm: $(pnpm -v)'"

# Tmux - unified launcher (tx --help for usage)
# tx          → Interactive picker (fzf)
# tx <project> → Start project (auto-detect template)
# tx .         → Start current directory
# tx --list    → List available templates

# Script Discovery & Test Helpers
alias .aero-scripts="ls -1 ~/code/dotfiles/bin/aerospace/ | column"
alias .tmux-scripts="ls -1 ~/code/dotfiles/bin/tmux/ | column"
alias .test-scripts="ls -1 ~/code/dotfiles/bin/test/ 2>/dev/null | column"
alias .test-clean="rm -rf ~/code/dotfiles/bin/test/*.sh && echo '✅ Test scripts cleaned'"

# Claude Code is already in PATH via Homebrew (/opt/homebrew/bin/claude)

# ----------------------------------------------------------------------------
# FZF (Fuzzy Finder) - If installed
# ----------------------------------------------------------------------------
export FZF_DEFAULT_OPTS='
  --ansi
  --height 40%
  --reverse
  --border
  --info=inline
  --color=fg:-1,bg:-1,hl:#5fff87
  --color=fg+:-1,bg+:-1,hl+:#ffaf5f
  --color=info:#af87ff,prompt:#5fff87,pointer:#ff87d7
  --color=marker:#ff87d7,spinner:#ff87d7
'
# Enable fzf keybindings (Ctrl+T for files, Ctrl+R for history)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ----------------------------------------------------------------------------
# Essential Plugins (lightweight, no Oh My Zsh needed!)
# ----------------------------------------------------------------------------

# Syntax highlighting - shows valid/invalid commands as you type
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Autosuggestions - suggests commands from history (use → to accept)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Atuin - magical shell history sync and search (Ctrl+R only, up arrow uses traditional behavior)
eval "$(atuin init zsh --disable-up-arrow)"

# Python alias - Homebrew installs as python3, alias for convenience
alias python='python3'
alias pip='pip3'

# ============================================================================
# END OF MINIMAL ZSHRC
# ============================================================================

# ----------------------------------------------------------------------------
# Bun Completions
# ----------------------------------------------------------------------------
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ============================================================================
# DEVELOPER PRODUCTIVITY ENHANCEMENTS
# ============================================================================

# ----------------------------------------------------------------------------
# 1. Smart Paste Protection
# ----------------------------------------------------------------------------
# Prevents accidentally running pasted commands with newlines
# Must press Enter to confirm
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

# ----------------------------------------------------------------------------
# 2. Sudo Toggle (Ctrl+S)
# ----------------------------------------------------------------------------
# Press Ctrl+S to add/remove sudo from current command
sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N sudo-command-line
bindkey "^S" sudo-command-line

# ----------------------------------------------------------------------------
# 4. Execution Time Display
# ----------------------------------------------------------------------------
# Shows how long each command took (only if >1 second)
# Merged into main precmd() function above
function preexec() {
  # Get timestamp in seconds, with error handling
  local timestamp=$(date +%s 2>/dev/null)
  if [[ "$timestamp" =~ ^[0-9]+$ ]]; then
    timer=$(($timestamp * 1000))
  else
    unset timer
  fi
}

# ----------------------------------------------------------------------------
# 6. Quick Extract Function
# ----------------------------------------------------------------------------
# Extract any archive: x archive.zip
x() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar x "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *)           echo "'$1' cannot be extracted via x()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# ----------------------------------------------------------------------------
# 7. Better Globbing
# ----------------------------------------------------------------------------
# Advanced file matching patterns
setopt EXTENDED_GLOB      # Enable extended globbing
setopt NULL_GLOB          # Don't error on no matches
setopt GLOB_DOTS          # Include dotfiles in globs

# ----------------------------------------------------------------------------
# 10. JSON/YAML Pretty Print
# ----------------------------------------------------------------------------
# Pretty print JSON from stdin or file
json() {
  if [ -t 0 ]; then
    # From file
    python3 -m json.tool "$@"
  else
    # From stdin
    python3 -m json.tool
  fi
}

# Pretty print YAML
yaml() {
  python3 -c 'import sys, yaml, json; print(json.dumps(yaml.safe_load(sys.stdin), indent=2))'
}

# ----------------------------------------------------------------------------
# 13. NPM/PNPM Aliases
# ----------------------------------------------------------------------------
alias ni="pnpm install"
alias nr="pnpm run"
alias nrs="pnpm start"
alias nrt="pnpm test"
alias nrd="pnpm run dev"
alias nrb="pnpm run build"
alias nrl="pnpm run lint"

# List available scripts from package.json (ADHD-friendly quick reference)
unalias scripts 2>/dev/null
scripts() {
  if [ ! -f package.json ]; then
    echo "No package.json found"
    return 1
  fi
  echo ""
  jq -r '.scripts | to_entries[] | "  \(.key)\t→ \(.value)"' package.json | column -t -s $'\t'
  echo ""
}

# ----------------------------------------------------------------------------
# 15. CD to Git Root
# ----------------------------------------------------------------------------
# Jump to git repository root
cdg() {
  local root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$root" ]; then
    cd "$root"
  else
    echo "Not in a git repository"
    return 1
  fi
}

# ============================================================================
# END DEVELOPER ENHANCEMENTS
# ============================================================================

# Docker CLI completions
fpath=($HOME/.docker/completions $fpath)

# ============================================================================
# ADHD-FRIENDLY TERMINAL STARTUP REMINDER
# ============================================================================
# Full quick reference display
show_quick_reference() {
  local node_ver=$(node -v 2>/dev/null | sed 's/v//')

  echo ""
  echo "  🧠 ADHD Quick Reference"
  echo "  ────────────────────────────────────"
  echo ""
  echo "  📦 Node ${node_ver} (shown in prompt)"
  echo ""
  echo "  🔥 Daily"
  echo "     morning    ☕ Start your day"
  echo "     qr         📋 Show this reference"
  echo ""
  echo "  ⚡ Navigation"
  echo "     cc         → Claude Code"
  echo "     lz         → LazyGit"
  echo "     cdg        → Jump to git root"
  echo "     d          → ~/code directory"
  echo ""
  echo "  🔧 Node Tools"
  echo "     node-lock  📌 Save .nvmrc"
  echo "     nv         📊 Version check"
  echo ""
  echo "  💡 Auto: Node switches on cd"
  echo "  ────────────────────────────────────"
  echo ""
}

# Alias for quick access
alias qr='show_quick_reference'
alias help='show_quick_reference'

# Shows helpful reminders when opening a new terminal (once per day)
terminal_reminder() {
  local reminder_file="$HOME/.cache/terminal_reminder_shown"
  local today=$(date +%Y-%m-%d)

  # Create cache directory if it doesn't exist
  mkdir -p "$HOME/.cache"

  # Check if we've shown the reminder today
  if [ -f "$reminder_file" ]; then
    local last_shown=$(cat "$reminder_file")
    if [ "$last_shown" = "$today" ]; then
      # Already shown - display compressed version
      echo "💡 Quick ref: \`qr\` | Node: [$(node -v | sed 's/v//')] | morning, cc, lz"
      return
    fi
  fi

  # Show the full reminder
  show_quick_reference

  # Mark as shown for today
  echo "$today" > "$reminder_file"
}

# Show reminder on terminal startup (but not in tmux panes)
if [ -z "$TMUX" ]; then
  terminal_reminder
fi
eval "$(pyenv init -)"

# PARA Obsidian CLI
alias para="bun run $HOME/code/side-quest-marketplace/plugins/para-obsidian/src/cli.ts"

# Work-specific config (proxy, clone helpers) - kept outside repo
[[ -f ~/.zshrc.work ]] && source ~/.zshrc.work

# ----------------------------------------------------------------------------
# Direnv (directory-specific env vars)
# ----------------------------------------------------------------------------
eval "$(direnv hook zsh)"

