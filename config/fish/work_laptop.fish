set -x JAVA_HOME (/usr/libexec/java_home)

set KARABINER_CONFIG "$HOME/code/dotfiles/config/karabiner/karabiner.json"

# Check if the specific keybinding exists in the configuration
if jq '.profiles[].complex_modifications.rules[] | select(.description == "Yabai: Move to another desktop space and focus on it using control + [number]")' "$KARABINER_CONFIG" | grep -q .
    cp "$KARABINER_CONFIG" "$KARABINER_CONFIG.bak"
    jq 'walk(if type == "object" and .description == "Yabai: Move to another desktop space and focus on it using control + [number]" then empty else . end)' "$KARABINER_CONFIG.bak" >"$KARABINER_CONFIG"
    rm -rf "$KARABINER_CONFIG.bak"
    git update-index --assume-unchanged $KARABINER_CONFIG
    echo "The specific keybinding exists in the configuration. Commenting out Karabiner binding that this work laptop does not support."
end

git config --global user.name "Nathan Vale"
git config --global user.email "nathan.vale@origin.com.au"
