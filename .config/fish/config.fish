set fish_greeting ""

set -gx TERM xterm-256color

# theme
set -g theme_color_scheme terminal-dark
set -g fish_prompt_pwd_dir_length 1
set -g theme_display_user yes
set -g theme_hide_hostname no
set -g theme_hostname always

# aliases
alias c="code ."
alias dotfiles="cd ~/code/dotfiles & c"
alias pg="echo 'Pinging Google' && ping www.google.com"
alias cb="code ~/.config/fish/config.fish"
alias sb="source ~/.config/fish/config.fish"
alias de="cd ~/Desktop"
alias d="cd ~/code"
alias s="/Applications/Android\ Studio.app/Contents/MacOS/studio"
alias ls "ls -p -G"
alias la "ls -A"
alias ll "ls -l"
alias lla "ll -A"
alias g git
alias ga="git add ."
# function gc 
#   git commit -m "$argv";  
# end
alias gpf='git push --force-with-lease' # Are you sure you want to do this???
alias gu "git reset --soft HEAD~"
alias karabiner_cli '/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli'
alias tiling "c $HOME/code/dotfiles/.config/skhd/skhdrc"

# CDPATH ALTERATIONS
set -gx CDPATH $CDPATH . ~ $HOME/code


set -gx EDITOR code

set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH

# NodeJS
set -gx PATH node_modules/.bin $PATH

# Go
set -g GOPATH $HOME/go
set -gx PATH $GOPATH/bin $PATH

# Python
set -gx PATH $HOME/.pyenv/shims:$PATH

# Grep
set -gx PATH /opt/homebrew/opt/grep/libexec/gnubin:$PATH

load_nvm > /dev/stderr

switch (uname)
  case Darwin
    source (dirname (status --current-filename))/config-osx.fish
  case Linux
    source (dirname (status --current-filename))/config-linux.fish
  case '*'
    source (dirname (status --current-filename))/config-windows.fish
end

set LOCAL_CONFIG (dirname (status --current-filename))/config-local.fish
if test -f $LOCAL_CONFIG
  source $LOCAL_CONFIG
end

fish_add_path /Users/nathanv/homebrew/bin
fish_add_path "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export JAVA_HOME=$HOME/Library/Java/JavaVirtualMachines/azul-11.0.19/Contents/Home
