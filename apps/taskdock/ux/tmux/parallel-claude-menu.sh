#!/bin/bash
# Parallel Claude Agent Launcher Menu
#
# Interactive menu for launching N parallel Claude agents.
# Provides quick-select options and custom input.
#
# Usage: Called from tmux keybinding (Ctrl-g P)

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
LAUNCHER="$SCRIPT_DIR/parallel-claude.sh"

# Color codes (for Ghostty compatibility)
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
NC=$'\033[0m'

# ============================================================================
# DISPLAY MENU
# ============================================================================

show_menu() {
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║  🤖 Parallel Claude Agent Launcher                            ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}How many agents do you want to launch?${NC}"
    echo ""
    echo -e "${GREEN}Quick Select:${NC}"
    echo -e "  ${BOLD}2${NC}  - Launch 2 agents (side-by-side)"
    echo -e "  ${BOLD}4${NC}  - Launch 4 agents (2x2 grid)"
    echo -e "  ${BOLD}8${NC}  - Launch 8 agents (4x2 grid)"
    echo -e "  ${BOLD}10${NC} - Launch 10 agents (5x2 grid)"
    echo ""
    echo -e "${YELLOW}Custom:${NC}"
    echo -e "  ${BOLD}c${NC}  - Enter custom number (1-50)"
    echo ""
    echo -e "${BLUE}Mode:${NC}"
    echo -e "  Append ${BOLD}n${NC} for new session (e.g., ${BOLD}4n${NC} for 4 agents in new session)"
    echo "  Default: current session"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  2    - 2 agents in current session"
    echo "  10n  - 10 agents in new dedicated session"
    echo "  c    - Custom number prompt"
    echo ""
    echo -en "${BOLD}Enter selection:${NC} "
}

# ============================================================================
# PARSE INPUT
# ============================================================================

parse_input() {
    local input="$1"
    local num_agents=""
    local mode="current"

    # Check for 'n' suffix (new session mode)
    if [[ "$input" =~ n$ ]]; then
        mode="new"
        input="${input%n}"  # Remove trailing 'n'
    fi

    # Parse selection
    case "$input" in
        2|4|8|10)
            num_agents="$input"
            ;;
        c)
            echo ""
            echo -en "${BOLD}Enter number of agents (1-50):${NC} "
            read custom_num
            if ! [[ "$custom_num" =~ ^[0-9]+$ ]] || [ "$custom_num" -lt 1 ] || [ "$custom_num" -gt 50 ]; then
                echo ""
                echo -e "${YELLOW}Invalid number. Using default (4).${NC}"
                num_agents="4"
            else
                num_agents="$custom_num"
            fi
            ;;
        *)
            echo ""
            echo -e "${YELLOW}Invalid selection. Using default (4 agents, current session).${NC}"
            num_agents="4"
            mode="current"
            ;;
    esac

    echo "$num_agents|$mode"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    show_menu
    read -r selection

    # Parse input
    local result=$(parse_input "$selection")
    IFS='|' read -r num_agents mode <<< "$result"

    # Clear screen for clean launcher output
    clear

    # Launch parallel claude
    echo ""
    echo -e "${GREEN}Launching $num_agents agents in $mode mode...${NC}"
    echo ""
    sleep 1

    "$LAUNCHER" "$num_agents" "$mode"
}

# Run main
main
