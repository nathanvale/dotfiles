set -x JAVA_HOME (/usr/libexec/java_home)

set KARABINER_CONFIG "$HOME/code/dotfiles/config/karabiner/karabiner.json"

# This work laptop does not support the specific keybinding for Yabai. So we
# need to remove from karabiner.json and the git index as we dont want to commit
# this back to dotfiles.
if jq '.profiles[].complex_modifications.rules[] | select(.description == "Yabai: Move to another desktop space and focus on it using control + [number]")' "$KARABINER_CONFIG" | grep -q .
    cp "$KARABINER_CONFIG" "$KARABINER_CONFIG.bak"
    jq 'walk(if type == "object" and .description == "Yabai: Move to another desktop space and focus on it using control + [number]" then empty else . end)' "$KARABINER_CONFIG.bak" >"$KARABINER_CONFIG"
    rm -rf "$KARABINER_CONFIG.bak"
    git update-index --assume-unchanged $KARABINER_CONFIG
    echo "The specific keybinding exists in the configuration. Commenting out Karabiner binding that this work laptop does not support."
end

# This function is used to change the current directory. If the custom_cd
# function is defined, it will be called with the provided arguments. If the
# current directory is a Git repository, it checks if it is the dotfiles
# repository. If it is the dotfiles repository, it sets the Git user name and
# email to "Nathan Vale" and "hi@nathanvale.com" respectively. Otherwise, it
# sets the Git user name and email to "Nathan Vale" and
# "nathan.vale@origin.com.au" respectively.
function cd
    builtin cd $argv
    load_nvm
    # Check if the directory is a Git repository
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1
        # Check if the repository is the dotfiles repository
        set repo_name (basename (git rev-parse --show-toplevel))
        if test "$repo_name" = dotfiles
            git config user.name "Nathan Vale"
            git config user.email "hi@nathanvale.com"
        else
            git config user.name "Nathan Vale"
            git config user.email "nathan.vale@origin.com.au"
        end
    end
end
