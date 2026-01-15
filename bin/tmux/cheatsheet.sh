#!/bin/bash
# bin/tmux/cheatsheet.sh
# Custom tmux keybinding cheatsheet

cat << 'EOF'
╭──────────────────────────────────────────────────────────────────────────────╮
│                        TMUX CHEATSHEET (Prefix: Ctrl-g)                      │
╰──────────────────────────────────────────────────────────────────────────────╯

 HELP & CONFIG
 ─────────────────────────────────────────────────────────────────────────────
   H           Show this cheatsheet          r           Reload tmux config

 SESSIONS
 ─────────────────────────────────────────────────────────────────────────────
   t           Project launcher (tx)         s           Session tree
   n           New session                   x           Kill session
   (  )        Previous/Next session         L           Last session
   Ctrl-\      Cycle sessions (no prefix)

 WINDOWS
 ─────────────────────────────────────────────────────────────────────────────
   1-4         Accordion: jump + zoom        5-9         Select window
   Tab         Last window                   w           Window tree
   Alt-1..9    Select window (no prefix)

 PANES
 ─────────────────────────────────────────────────────────────────────────────
   |           Split horizontal              -           Split vertical
   h j k l     Navigate (vim-style)          Alt-arrows  Navigate (no prefix)
   z           Toggle zoom                   Alt-z       Toggle zoom (no prefix)
   Space       Toggle zoom (accordion)       y           Sync panes toggle
   < >         Swap pane up/down

 LAYOUTS
 ─────────────────────────────────────────────────────────────────────────────
   T           Tiled (equal)                 E           Even horizontal
   S           Even vertical

 AI AGENTS
 ─────────────────────────────────────────────────────────────────────────────
   A c         Spawn Claude                  A g         Spawn Gemini
   A x         Spawn Codex                   A o         Spawn OpenAI
   A n         New AI window                 A v         Claude (vertical)
   A w         Worktree wizard (4 panes)     U           Upgrade AI tools
   B           Broadcast toggle (sync panes)

 COPY MODE (vi-style)
 ─────────────────────────────────────────────────────────────────────────────
   [           Enter copy mode               /  ?        Search forward/back
   v           Begin selection               y           Copy to clipboard
   Escape      Cancel

 OTHER
 ─────────────────────────────────────────────────────────────────────────────
   c           Open in VS Code               g           GitHub browse
   a           WorkSafe login

╭──────────────────────────────────────────────────────────────────────────────╮
│  Press q to close                                                            │
╰──────────────────────────────────────────────────────────────────────────────╯
EOF

read -rsn1
