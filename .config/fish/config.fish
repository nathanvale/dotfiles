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
command -qv nvim && alias vim nvim
alias ga="git add ."
function gc 
  git commit -m "$argv";  
end
alias gpf='git push --force-with-lease' # Are you sure you want to do this???
alias gu "git reset --soft HEAD~"
alias karabiner_cli '/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli'

## util functions
function mg
  mkdir "$argv" && cd "$argv" || exit;
end
function killport
  lsof -i tcp:"$argv" | awk 'NR!=1 {print $2}' | xargs kill -9 ;
end
function ide
  tmux split-window -v -p 30
  tmux split-window -h -p 66
  tmux split-window -h -p 50
end

function removeKPrefs
  rm -rf  ~/.config/karabiner
  rm -rf  ~/.local/share/karabiner
  rm -rf  ~/Library/Preferences/org.pqrs.Karabiner-Elements.Preferences.plist
  rm -rf  ~/Library/Preferences/org.pqrs.Karabiner-Elements.Updater.plist
  rm -rf  ~/Library/Preferences/org.pqrs.Karabiner-EventViewer.plist
  rm -rf  ~/Library/Preferences/org.pqrs.Karabiner-Menu.plist
  rm -rf  ~/Library/Preferences/org.pqrs.Karabiner-MultitouchExtension.plist
end
# CDPATH ALTERATIONS
set -gx CDPATH $CDPATH . ~ $HOME/code


set -gx EDITOR nvim

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

# Sports bet stuff

export NODE_EXTRA_CA_CERTS=$HOME/sportsbet-root-ca.pem

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk

fish_add_path $ANDROID_HOME/emulator
fish_add_path $ANDROID_HOME/tools
fish_add_path $ANDROID_HOME/tools/bin
fish_add_path $ANDROID_HOME/platform-tools

function fireUpSportsBetWebDev
	cd /Users/nathanv/code/hydra
  kill_terminals
	brew services restart nginx
	yarn build-web-for-local-dev
end

alias bw "fireUpSportsBetWebDev"