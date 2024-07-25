eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.bin:$PATH"
alias ll='ls -la'
# NVM (Node Version Manager) setup
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


