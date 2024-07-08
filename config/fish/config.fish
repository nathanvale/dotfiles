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
  --color=fg:#D7DEEA,bg:#051526,hl:#BF94E4
  --color=fg+:#FFFFFF,bg+:#073642,hl+:#BF94E4
  --color=info:#84ACFF,prompt:#84ACFF,pointer:#EC6477
  --color=marker:#d33682,spinner:#84ACFF,header:#C4A012
  --color=query:#BF94E4,border:#687778
  --cycle --layout=reverse --border --height=90% --preview-window=wrap --marker="*"'

set -x LS_COLORS 'di=38;2;149;217;202:fi=38;2;215;222;234:*=38;2;215;222;234:*.ts=38;2;99;119;119:*.tsx=38;2;99;119;119:*.js=38;2;99;119;119:*.jsx=38;2;99;119;119'

# # CDPATH ALTERATIONS
set -gx CDPATH $CDPATH . ~ $HOME/code

set -gx EDITOR code

set -gx PATH bin $PATH
set -gx PATH ~/.bin $PATH
set -gx PATH /opt/homebrew/bin $PATH
set -gx PATH node_modules/.bin $PATH
set -gx PATH ~/Library/Python/3.9/bin $PATH

# Add these lines to your config.fish file
set -U pure_color_normal '#D6D38E'
set -U pure_color_info '#82AAFF'
set -U pure_color_primary '#82AAFF'
set -U pure_color_mute '#565656'
set -U pure_color_success '#22D14E'
set -U pure_color_caution '#ADDB8F'
set -U pure_color_error '#EC6477'
set -U pure_color_critical '#EC6477'

# Remove previous universal variable settings if any
set -e fish_color_normal
set -e fish_color_command
set -e fish_color_quote
set -e fish_color_redirection
set -e fish_color_end
set -e fish_color_error
set -e fish_color_param
set -e fish_color_comment
set -e fish_color_selection
set -e fish_color_search_match
set -e fish_color_operator
set -e fish_color_escape
set -e fish_color_autosuggestion
set -e fish_color_user
set -e fish_color_host
set -e fish_color_cwd
set -e fish_color_cwd_root
set -e fish_color_valid_path
set -e fish_color_white
set -e fish_color_completion

# Set new colors based on Night Owl theme
set -U fish_color_normal '#D7DEEA'
set -U fish_color_command '#CBE386'
set -U fish_color_quote '#D7DEEA'
set -U fish_color_redirection '#82AAFF'
set -U fish_color_end '#82AAFF'
set -U fish_color_error '#EC6477'
# set -U fish_color_param ??? 
set -U fish_color_comment '#565656'
# set -U fish_color_selection ???
set -U fish_color_search_match --background='333'
# set -U fish_color_operator ??? 
# set -U fish_color_escape ??? 
# set -U fish_color_completion ??? 
set -U fish_color_autosuggestion '#565656'
# set -U fish_color_user ??? 
# set -U fish_color_host ??? 
set -U fish_color_cwd '#95D9CA'
# set -U fish_color_cwd_root ??? 
set -U fish_color_valid_path '#95D9CA'
set -U fish_color_white '#D7DEEA'





set -gx FD_OPTIONS "--color=always"

function cd
    builtin cd $argv
    load_nvm >/dev/stderr
end
