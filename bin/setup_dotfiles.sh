# /bin/bash

# yabai uses the macOS Mach APIs to inject code into Dock.app; this requires
# elevated (root) privileges. You can configure your user to execute yabai
# --load-sa as the root user without having to enter a password. To do this,
# we add a new configuration entry that is loaded by /etc/sudoers.
# https://tinyurl.com/27vdt398

# dss
echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai

curl -L https://iterm2.com/shell_integration/fish \
	-o ~/.iterm2_shell_integration.fish
