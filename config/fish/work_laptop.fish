set -x JAVA_HOME (/usr/libexec/java_home)

set KARABINER_CONFIG "$HOME/code/dotfiles/config/karabiner/karabiner.json"

# This work laptop does not support the specific keybinding for Yabai. So we
# need to remove from karabiner.json and the git index as we dont want to commit
# this back to dotfiles.
if jq '.profiles[].complex_modifications.rules[] | select(.description == "Yabai: Move to another desktop space and focus on it using control + [number]")' "$KARABINER_CONFIG" | grep -q .
    cp "$KARABINER_CONFIG" "$KARABINER_CONFIG.bak"
    jq 'walk(if type == "object" and .description == "Yabai: Move to another desktop space and focus on it using control + [number]" then empty else . end)' "$KARABINER_CONFIG.bak" >"$KARABINER_CONFIG"
    rm -rf "$KARABINER_CONFIG.bak"
    sleep 1
    git update-index --assume-unchanged $KARABINER_CONFIG
    echo "The specific keybinding exists in the configuration. Commenting out Karabiner binding that this work laptop does not support."
end
