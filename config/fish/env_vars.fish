# Define the custom functions directory
set custom_function_dir ~/.config/fish/functions/custom

# Ensure the custom functions directory exists
if not test -d $custom_function_dir
    mkdir -p $custom_function_dir
end

# Add the custom functions directory to the function path if it's not already present
if not contains $custom_function_dir $fish_function_path
    set -U fish_function_path $custom_function_dir $fish_function_path
    # In Fish shell, environment variables set with set -U (universal variables)
    # are stored persistently, but they only take effect for new shell sessions.
    # Therefore, if you want the changes to be effective immediately in your
    # current session, you need to set the variable with the -g flag for the
    # current session. 
    set -g fish_function_path $custom_function_dir $fish_function_path
end

set fzf_directory_opts --bind "ctrl-o:execute($EDITOR {} &> /dev/tty)"

set fzf_preview_dir_cmd 'eza -a --color=always --icons'

set -gx TERM xterm-256color

set -U fish_user_paths (/opt/homebrew/bin/brew --prefix grep)/libexec/gnubin $fish_user_paths

# NVM
set -x NVM_DIR $HOME/.nvm

# Set bat as the default pager
set -U PAGER bat

# Set the custom theme for bat
set -U BAT_THEME "Night Owl"

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
set -gx PATH node_modules/.bin $PATH
set -gx PATH ~/Library/Python/3.9/bin $PATH


# Set the tide colors based on Night Owl theme
set -U tide_pwd_color_anchors 84ACFF #84ACFF
set -U tide_pwd_color_dirs 5F7E97 #5F7E97
set -U tide_pwd_color_root EC6477 #EC6477
set -U tide_git_color_branch 7FDBCA #7FDBCA
set -U tide_git_color_conflicted ff2c83 #ff2c83
set -U tide_git_color_dirty FAD430 #FAD430
set -U tide_git_color_operation ff2c83 #ff2c83
set -U tide_git_color_staged FAD430 #FAD430
set -U tide_git_color_stash CBE386 #CBE386
set -U tide_git_color_untracked 84ACFF #84ACFF
set -U tide_git_color_upstream CBE386 #CBE386
set -U tide_character_color CBE386 #CBE386
set -U tide_character_color_failure ff2c83 #ff2c83
set -U tide_time_color 5F7E97 #5F7E97
set -U tide_cmd_duration_color 5F7E97 #5F7E97
set -U tide_status_color CBE386 #CBE386
set -U tide_status_color_failure ff2c83 #ff2c83 

set -U tide_os_icon ""


# Set new colors based on Night Owl theme
set -U fish_color_normal '#D7DEEA'
set -U fish_color_command '#CBE386'
set -U fish_color_quote '#D7DEEA'
set -U fish_color_redirection '#82AAFF'
set -U fish_color_end '#82AAFF'
set -U fish_color_error '#EC6477'
set -e fish_color_param
set -U fish_color_comment '#5F7E97'
set -e fish_color_selection
set -e fish_color_search_match
set -e fish_color_operator
set -e fish_color_escape
set -U fish_color_completion #EC6477
set -U fish_color_autosuggestion '#5F7E97'
set -e fish_color_user
set -e fish_color_host
set -U fish_color_cwd '#D8DEEA'
set -e fish_color_cwd_root
set -U fish_color_valid_path '#D8DEEA'
set -U fish_color_white '#D7DEEA'

set -gx FD_OPTIONS "--color=always"

# HOMEBREW PATHS
eval "$(/opt/homebrew/bin/brew shellenv)"

# HOMEBREW_BUNDLE_FILE_GLOBAL
set -gx HOMEBREW_BUNDLE_FILE_GLOBAL ~/.config/brew/Brewfile
set -gx HOMEBREW_BUNDLE_FILE ~/.config/brew/Brewfile
