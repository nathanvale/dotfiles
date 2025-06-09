# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git gh pnpm azure z fzf history zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='code'
else
    export EDITOR='code'
fi

export FZF_DEFAULT_OPTS='
  --ansi
  --color=fg:#D8DEEA,bg:#011627,hl:#FFFFFF:bold
  --color=fg+:#FFFFFF,bg+:#253A52,hl+:#FFFFFF:bold
  --color=info:#7FDBCA,prompt:#84ACFF,pointer:#EC6477
  --color=marker:#ff2c83,spinner:#FAD430,header:#C4A012
  --color=query:#FFFFFF,border:#5F7E97
  --cycle --layout=reverse --border --height=90% --preview-window=wrap --marker="*"'

export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME/bin:$PATH"

export PATH="/opt/homebrew/bin:$PATH"

if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export HOMEBREW_BUNDLE_FILE_GLOBAL="$HOME/.config/brew/Brewfile"
export HOMEBREW_BUNDLE_FILE="$HOME/.config/brew/Brewfile"

export XDG_CONFIG_HOME="$HOME/.config"

export TERM=xterm-256color

export DOTFILES_GENIE_DIR="$HOME/code/dotfiles/genie"
export PATH="$HOME/code/dotfiles/genie/bin:$PATH"

# NVM (Node Version Manager) setup
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export PAGER="bat"
export BAT_THEME="Night Owl"

export CDPATH=".:~:$HOME/code"

export PATH=$HOME/code/dotfiles/genie/scripts:$PATH

export LANG="en_AU.UTF-8"
export LC_COLLATE="en_AU.UTF-8"
export LC_CTYPE="en_AU.UTF-8"
export LC_MESSAGES="en_AU.UTF-8"
export LC_MONETARY="en_AU.UTF-8"
export LC_NUMERIC="en_AU.UTF-8"
export LC_TIME="en_AU.UTF-8"
export LC_ALL="en_AU.UTF-8"

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Eza aliases
alias ls="eza --color=always --icons"
alias ll="eza -l --color=always --icons"
alias lla="eza -l -a --color=always --icons"
alias la="eza -a --color=always --icons"
alias lt="eza --tree --color=always --icons"

# Open the current directory in VS Code
alias c="code ."

# Ping Google with a message
alias pg="echo 'Pinging Google' && ping www.google.com"

# Change directory to Desktop
alias de="cd ~/Desktop"

# Change directory to code
alias d="cd ~/code"

# Use bat instead of cat
alias cat="bat"

# Use bat with line numbers
alias batn="bat -n"

# Use grm instead of rm
alias rm="grm"

# Use gmv instead of mv
alias mv="gmv"

# Use bat instead of less
alias less="bat"

# Use bat without paging instead of cat
alias cat="bat --paging=never"

# Use lazygit instead of lz
alias lz="lazygit"

# Open VS Code with the current directory and a specific file
alias ca="code . ~/code/dotfiles/config/aerospace/aerospace.toml"

# Reload aerospace configuration
alias sa="aerospace reload-config"

# Open Fish configuration file in VS Code
alias cz="code ~/.zshrc"

# Source Fish configuration file
alias sz="source ~/.zshrc"

# Change directory to CSP, use nvm, and open in VS Code
alias p.csp="cd ~/code/CSP/ && nvm use && code ."

# Change directory to dotfiles and open in VS Code
alias p.dotfiles="cd ~/code/dotfiles/ && code ."

# Write current Node.js version to .nvmrc
alias w.nvmrc="node -v > .nvmrc"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


