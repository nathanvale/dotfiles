# ----------------------------------------------------------------------------
# PATH Setup
# ----------------------------------------------------------------------------
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME/bin:$PATH"

# Add dotfiles scripts to PATH
export PATH="$HOME/code/dotfiles/bin:$PATH"
export PATH="$HOME/code/dotfiles/bin/aerospace:$PATH"
export PATH="$HOME/code/dotfiles/bin/tmux:$PATH"
export PATH="$HOME/code/dotfiles/bin/vault:$PATH"
export PATH="$HOME/code/dotfiles/bin/utils:$PATH"

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
# Load Secrets (MCP API keys, Azure credentials, etc.)
# ----------------------------------------------------------------------------
if [ -f "$HOME/code/dotfiles/.env.secrets" ]; then
  source "$HOME/code/dotfiles/.env.secrets"
fi

# ----------------------------------------------------------------------------
# NVM (Node Version Manager)
# ----------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# Auto-switch Node version based on .nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc < /dev/null

# ----------------------------------------------------------------------------
# Prompt with Git Branch Support + Execution Time
# ----------------------------------------------------------------------------
autoload -Uz vcs_info
precmd() {
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
        if [ $? -eq 0 ]; then
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
PROMPT='%F{cyan}%1~%f %F{green}${vcs_info_msg_0_}%f%(?.%(!.#.>).%(!.#.>)) '
RPS1=''  # Clear right prompt
PS2='> '

# ----------------------------------------------------------------------------
# History Configuration
# ----------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS

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
d() { cd ~/code; }          # Quick jump to code directory (overrides Oh My Zsh)
alias de="cd ~/Desktop"
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
  if [ -t 1 ]; then
    # Output is to terminal - use bat for pretty display
    command bat --paging=never "$@"
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

# Utilities
alias pg="echo 'Pinging Google' && ping www.google.com"

# Claude Code
alias cc="claude --dangerously-skip-permissions"
alias ccr="claude --dangerously-skip-permissions -r"

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

# Projects
alias p.dotfiles="cd ~/code/dotfiles/ && code ."

# Node
alias w.nvmrc="node -v > .nvmrc"

# Tmux
alias tx='~/code/dotfiles/bin/tmux/startup.sh'
alias tmuxnew='~/code/dotfiles/bin/tmux/new-project.sh'
alias tnew='~/code/dotfiles/bin/tmux/new-project.sh'

# Function to jump to a project directory and start tmuxinator
tcd() {
    if [ $# -eq 0 ]; then
        echo "Usage: tcd <project-name>"
        return 1
    fi

    local project_dir="$HOME/code/$1"

    if [ ! -d "$project_dir" ]; then
        echo "Project directory not found: $project_dir"
        return 1
    fi

    cd "$project_dir"

    # Check if tmuxinator config exists
    if [ -f "$HOME/.config/tmuxinator/$1.yml" ]; then
        tmuxinator start "$1"
    else
        echo "No tmuxinator config found for $1"
        read -q "?Generate one now? (y/n): "
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ~/code/dotfiles/bin/tmux/new-project.sh "$1"
        fi
    fi
}

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

# Atuin - magical shell history sync and search
eval "$(atuin init zsh)"

# Python alias - Homebrew installs as python3, alias for convenience
alias python='python3'
alias pip='pip3'

# ============================================================================
# END OF MINIMAL ZSHRC
# ============================================================================

# ----------------------------------------------------------------------------
# Tmux Auto-Startup
# ----------------------------------------------------------------------------
if [ -z "$TMUX_STARTUP_RAN" ]; then
  export TMUX_STARTUP_RAN=1
  if [ -f ~/code/dotfiles/bin/tmux/startup.sh ]; then
    ~/code/dotfiles/bin/tmux/startup.sh
  fi
fi

# ----------------------------------------------------------------------------
# Bun Completions & PATH
# ----------------------------------------------------------------------------
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ----------------------------------------------------------------------------
# Ensure Homebrew takes priority over NVM and Bun
# ----------------------------------------------------------------------------
# This must come after NVM and Bun setup to override their PATH additions
export PATH="/opt/homebrew/bin:$PATH"

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
