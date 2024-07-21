# Example Aliases
# https://fishshell.com/docs/current/cmds/abbr.html

abbr -a --position anywhere -- -C --color
abbr -a L --position anywhere --set-cursor "% | less"
function last_history_item
    echo $history[1]
end
abbr -a !! --position anywhere --function last_history_item
function code_edit
    echo vim $argv
end
abbr -a code_edit_texts --position command --regex ".+\.txt" --function code_edit

abbr 4DIRS --set-cursor=! "$(string join \n -- 'for dir in */' 'cd $dir' '!' 'cd ..' 'end')"


# Custom Aliases

abbr -a c "code ."
abbr -a pg "echo 'Pinging Google' && ping www.google.com"
abbr -a cf "code ~/.config/fish/config.fish"
abbr -a sf "source ~/.config/fish/config.fish"
abbr -a de "cd ~/Desktop"
abbr -a d "cd ~/code"
abbr -a cat bat
abbr -a batn "bat -n"
abbr -a ghpr gh_create_pr_and_merge
abbr -a ghli "gh auth login"
abbr -a ghlo "gh auth logout"

abbr -a ls "eza --color=always --icons"
abbr -a ll "eza -l --color=always --icons"
abbr -a lla "eza -l -a --color=always --icons"
abbr -a la "eza -a --color=always --icons"
abbr -a lt "eza --tree --color=always --icons"

abbr -a rm grm
abbr -a mv gmv

abbr -a less bat
abbr -a cat "bat --paging=never"

alias -s cd="custom_cd"
