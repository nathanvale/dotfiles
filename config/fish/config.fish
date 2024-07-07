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

# aliases

alias c="code ."
alias pg="echo 'Pinging Google' && ping www.google.com"
alias cb="code ~/.config/fish/config.fish"
alias sb="source ~/.config/fish/config.fish"
alias de="cd ~/Desktop"
alias d="cd ~/code"
alias mp="make prepare"
alias open_plugin_git_readme="open https://github.com/jhillyerd/plugin-git"

# # CDPATH ALTERATIONS
set -gx CDPATH $CDPATH . ~ $HOME/code

set -gx EDITOR code

set -gx PATH bin $PATH
set -gx PATH ~/.bin $PATH
set -gx PATH /opt/homebrew/bin $PATH
set -gx PATH node_modules/.bin $PATH
set -gx PATH ~/Library/Python/3.9/bin $PATH

function cd
    builtin cd $argv
    load_nvm >/dev/stderr
end
