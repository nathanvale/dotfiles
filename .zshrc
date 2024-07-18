export PATH="$HOME/bin:$PATH"
alias ll='ls -la'

# NVM (Node Version Manager) setup
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

switch_to_fish() {
    if command -v fish >/dev/null 2>&1; then
        exec fish
    else
        echo "fish shell is not installed. Please install fish first."
    fi
}
eval "$(/opt/homebrew/bin/brew shellenv)"
