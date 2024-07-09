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
  --ansi
  --color=fg:#D8DEEA,bg:#011627,hl:#FFFFFF:bold
  --color=fg+:#FFFFFF,bg+:#253A52,hl+:#FFFFFF:bold
  --color=info:#7FDBCA,prompt:#84ACFF,pointer:#ff5874
  --color=marker:#ff2c83,spinner:#FAD430,header:#C4A012
  --color=query:#FFFFFF,border:#5F7E97
  --cycle --layout=reverse --border --height=90% --preview-window=wrap --marker="*"'

set -x LS_COLORS 'di=38;2;216;222;234:fi=216;222;234:*=216;222;234:*.ts=38;2;130;170;255:*.tsx=38;2;130;170;255:*.js=38;2;130;170;255:*.jsx=38;2;130;170;255:*.fish=38;2;203;227;134:*.sh=38;2;203;227;134'

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
set -U pure_color_mute '#5F7E97'
set -U pure_color_success '#22D14E'
set -U pure_color_caution '#ADDB8F'
set -U pure_color_error '#ff5874'
set -U pure_color_critical '#ff5874'

set -g async_prompt_functions _pure_prompt_git

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
set -U fish_color_param default
set -U fish_color_comment '#5F7E97'
set -U fish_color_selection default
set -U fish_color_search_match default
set -U fish_color_operator default
set -U fish_color_escape default
set -U fish_color_completion #EC6477
set -U fish_color_autosuggestion '#5F7E97'
set -U fish_color_user default
set -U fish_color_host default
set -U fish_color_cwd '#D8DEEA'
set -U fish_color_cwd_root default
set -U fish_color_valid_path '#D8DEEA'
set -U fish_color_white '#D7DEEA'





set -gx FD_OPTIONS "--color=always"

function cd
    builtin cd $argv
    load_nvm >/dev/stderr
end
