#!/bin/bash

# Create symlink for tmux configuration
ln -sf ~/.config/dotfiles/config/tmux/tmux.conf ~/.tmux.conf

echo "✅ tmux configuration symlinked successfully!"
echo "Run 'tmux source ~/.tmux.conf' to reload config in existing sessions."
