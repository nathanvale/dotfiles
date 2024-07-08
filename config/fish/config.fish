set fish_greeting "Hello Nathan!"

fzf_configure_bindings --directory=\cf --processes=\cp --variables=\cv -git_status=\cS --git_log=\cL


set fzf_directory_opts --bind "ctrl-o:execute($EDITOR {} &> /dev/tty)"

set -gx TERM xterm-256color

# Define the custom functions directory
set custom_function_dir ~/.config/fish/functions/custom

# Ensure the custom functions directory exists
if not test -d $custom_function_dir
    mkdir -p $custom_function_dir
end

# Add the custom functions directory to the function path if it's not already present
if not contains $custom_function_dir $fish_function_path
    set -U fish_function_path $fish_function_path $custom_function_dir
end

set -U fish_user_paths (brew --prefix grep)/libexec/gnubin $fish_user_paths

# aliases

alias c="code ."
alias pg="echo 'Pinging Google' && ping www.google.com"
alias cb="code ~/.config/fish/config.fish"
alias sb="source ~/.config/fish/config.fish"
alias de="cd ~/Desktop"
alias d="cd ~/code"
alias open_plugin_git_readme="open https://github.com/jhillyerd/plugin-git"
# Bat is a better version of cat
alias cat='bat'
alias batn='bat -n' # Alias to show line numbers
# Eza is a better version of ls

alias ls='eza --color=always --icons' # Alias ls command with eza options for colored output and icons 
alias ll='eza -l --color=always --icons' # Alias ll command with eza options for long format, colored output, and icons
alias la='eza -a --color=always --icons' # Alias la command with eza options for all files, colored output, and icons
alias lt='eza --tree --color=always --icons' # Alias lt command with eza options for tree view, colored output, and icons

set fzf_preview_dir_cmd la

# Core utilities package
alias rm grm
alias mv gmv

# Origin Energy aliases
alias mp="make prepare"

# Set bat as the default pager
set -U PAGER bat

# Set the custom theme for bat
set -U BAT_THEME Night-Owl

# Alias less to bat for convenience
alias less="bat"
alias cat="bat --paging=never"

# Set FZF default options based on Night Owl theme
set -Ux FZF_DEFAULT_OPTS '
  --color=fg:#8EA3B9,bg:#051526,hl:#B7DA76
  --color=fg+:#FFFFFF,bg+:#073642,hl+:#B7DA76
  --color=info:#268bd2,prompt:#859900,pointer:#dc322f
  --color=marker:#d33682,spinner:#2aa198,header:#C4A012
  --color=query:#B7DA76
  --cycle --layout=reverse --border --height=90% --preview-window=wrap --marker="*"'

set -x LS_COLORS "di=38;2;95;196;169:fi=0;38;5;67:ln=1;36:pi=40;33:so=1;32:bd=40;33;01:cd=40;33;01:or=31;01:ex=1;31:*.txt=1;34:*.md=1;36:*.json=1;33"



# # CDPATH ALTERATIONS
set -gx CDPATH $CDPATH . ~ $HOME/code

set -gx EDITOR code

set -gx PATH bin $PATH
set -gx PATH ~/.bin $PATH
set -gx PATH /opt/homebrew/bin $PATH
set -gx PATH node_modules/.bin $PATH
set -gx PATH ~/Library/Python/3.9/bin $PATH

set -gx FD_OPTIONS "--color=always"

function cd
    builtin cd $argv
    load_nvm >/dev/stderr
end
