#!/bin/bash

source $HOME/.aliases

export TERM=xterm-256color
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# PROMPT STUFF
GREEN=$(tput setaf 2);
YELLOW=$(tput setaf 3);
RESET=$(tput sgr0);

function git_branch {
  # Shows the current branch if in a git repository
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\ \(\1\)/';
}

function random_element {
  declare -a array=("$@")
  r=$((RANDOM % ${#array[@]}))
  printf "%s\n" "${array[$r]}"
}

# Default Prompt
setEmoji () {
  EMOJI="$*"
  PS1="${YELLOW}\w${GREEN}\$(git_branch)${RESET} ${EMOJI}\n$ ";
}

newRandomEmoji () {
  setEmoji "$(random_element 😅 👽 🔥 🚀 👻 ⛄ 👾 🍔 😄 🍰 🐑 😎 🏎 🤖 😇 😼 💪 🦄 🥓 🌮 🎉 💯 ⚛️ 🐠 🐳 🐿 🥳 🤩 🤯 🤠 👨‍💻 🦸‍ 🧝‍ 🧞‍ 🧙‍ 👨‍🚀 👨‍🔬 🕺 🦁 🐶 🐵 🐻 🦊 🐙 🦎 🦖 🦕 🦍 🦈 🐊 🦂 🐍 🐢 🐘 🐉 🦚 ✨ ☄️ ⚡️ 💥 💫 🧬 🔮 ⚗️ 🎊 🔭 ⚪️ 🔱)"
}

newRandomEmoji

alias jestify="PS1=\"🃏\n$ \"";
alias cypressify="PS1=\"🌀\n$ \"";

# history size
HISTSIZE=5000
HISTFILESIZE=10000

# PATH ALTERATIONS
## Node
PATH="/usr/local/bin:$PATH:./node_modules/.bin";

# Custom bins
PATH="$PATH:$HOME/.bin";
# dotfile bins
PATH="$PATH:$HOME/.my_bin";

# CDPATH ALTERATIONS
CDPATH=.:$HOME:$HOME/code:$HOME/Desktop


# Bash completion
if [ -f "$(brew --prefix)/etc/bash_completion" ]; then
. "$(brew --prefix)/etc/bash_completion"
fi


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
