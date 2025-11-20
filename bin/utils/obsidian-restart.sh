#!/bin/bash
# obsidian-restart.sh - Restart Obsidian to pick up vault changes

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 Restarting Obsidian...${NC}"

# Check if Obsidian is running
if pgrep -f "Obsidian" > /dev/null; then
    echo -e "${YELLOW}Closing Obsidian...${NC}"
    osascript -e 'quit application "Obsidian"'
    sleep 2
fi

# Start Obsidian
echo -e "${GREEN}Starting Obsidian...${NC}"
open -a Obsidian

echo -e "${GREEN}✅ Obsidian restarted${NC}"