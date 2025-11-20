#!/bin/bash
# tmuxinator-new-project.sh - Automatically generate tmuxinator config for new projects
# Follows standard template: claude -> git -> [project-specific windows]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Vault paths (apps live under apps/, CLI shim in bin/)
DOTFILES_ROOT="$HOME/code/dotfiles"
VAULT_SHIM="$DOTFILES_ROOT/bin/vault"
VAULT_LIB_DIR="$DOTFILES_ROOT/apps/vault/lib"

# Get project name from argument or current directory
if [ $# -eq 0 ]; then
    PROJECT_NAME=$(basename "$PWD")
    PROJECT_PATH="$PWD"
else
    PROJECT_NAME="$1"
    # Check if the project exists in ~/code/ or use current directory
    if [ -d "$HOME/code/$PROJECT_NAME" ]; then
        PROJECT_PATH="$HOME/code/$PROJECT_NAME"
    elif [ -d "./$PROJECT_NAME" ]; then
        PROJECT_PATH="$(pwd)/$PROJECT_NAME"
    else
        # Default to current directory if project not found
        PROJECT_PATH="$PWD"
    fi
fi

# Comprehensive project name normalization function
normalize_project_name() {
    local name="$1"
    local original_name="$name"

    # Remove leading/trailing whitespace
    name=$(echo "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Handle empty name
    if [ -z "$name" ]; then
        echo "unnamed-project"
        return
    fi

    # Handle names starting with dots - replace with "dot-" prefix
    if [[ "$name" =~ ^\.+ ]]; then
        # Remove leading dots and add "dot-" prefix
        name=$(echo "$name" | sed 's/^\.*//')
        if [ -z "$name" ]; then
            name="hidden"
        fi
        name="dot-${name}"
    fi

    # Replace problematic characters
    name=$(echo "$name" | tr '.' '-')        # Dots become dashes (critical for tmuxinator)
    name=$(echo "$name" | tr ' /' '-')       # Spaces and slashes become dashes
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')  # Convert to lowercase
    name=$(echo "$name" | sed 's/[$`|&;()<>]/-/g')    # Shell metacharacters become dashes
    name=$(echo "$name" | sed 's/[^a-z0-9-]/-/g')     # Any remaining non-alphanumeric/dash chars become dashes
    name=$(echo "$name" | sed 's/-\+/-/g')            # Clean up multiple consecutive dashes
    name=$(echo "$name" | sed 's/^-\+//;s/-\+$//')    # Remove leading/trailing dashes

    # Handle empty result after sanitization
    if [ -z "$name" ]; then
        name="sanitized-project"
    fi

    # Handle length limit (keep under 50 chars for tmux display)
    if [ ${#name} -gt 50 ]; then
        name=$(echo "$name" | cut -c1-47)
        name="${name}..."
    fi

    # Handle reserved names
    case "$name" in
        "default"|"main"|"master"|"root"|"admin"|"system"|"tmp"|"temp")
            name="${name}-project"
            ;;
    esac

    echo "$name"
}

# Show user feedback when project name normalization occurs
show_normalization_feedback() {
    local original="$1"
    local normalized="$2"

    if [ "$original" != "$normalized" ]; then
        echo -e "${YELLOW}📝 Project name normalized for tmuxinator compatibility:${NC}"
        echo -e "   Original: ${RED}$original${NC}"
        echo -e "   Normalized: ${GREEN}$normalized${NC}"
        echo -e "${BLUE}   Why: Tmuxinator requires names without dots, special chars, or leading dots${NC}"
        echo
    fi
}

# Normalize project name for safe use in tmuxinator/tmux
SAFE_PROJECT_NAME=$(normalize_project_name "$PROJECT_NAME")
CONFIG_FILE="$HOME/.config/tmuxinator/${SAFE_PROJECT_NAME}.yml"

# Show feedback if normalization occurred
show_normalization_feedback "$PROJECT_NAME" "$SAFE_PROJECT_NAME"

echo -e "${BLUE}🚀 Generating tmuxinator config for project: ${YELLOW}$PROJECT_NAME${NC}"

# Check if config already exists
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}⚠️  Config already exists: $CONFIG_FILE${NC}"
    read -p "Overwrite? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Aborted${NC}"
        exit 1
    fi
fi

# Detect project type and determine additional windows
detect_project_type() {
    local extra_windows=""

    # Check for Next.js / Node.js project
    if [ -f "$PROJECT_PATH/package.json" ]; then
        echo -e "${GREEN}✓ Detected Node.js/JavaScript project${NC}" >&2

        # Check for specific frameworks
        if grep -q '"next"' "$PROJECT_PATH/package.json" 2>/dev/null; then
            echo -e "${GREEN}  → Next.js framework detected${NC}" >&2
            extra_windows="nextjs"

            # Check for additional tools
            if grep -q '"@storybook' "$PROJECT_PATH/package.json" 2>/dev/null; then
                echo -e "${GREEN}  → Storybook detected${NC}" >&2
                extra_windows="$extra_windows storybook"
            fi

            if grep -q '"prisma"' "$PROJECT_PATH/package.json" 2>/dev/null || [ -f "$PROJECT_PATH/prisma/schema.prisma" ]; then
                echo -e "${GREEN}  → Prisma detected${NC}" >&2
                extra_windows="$extra_windows prisma"
            fi
        elif grep -q '"react"' "$PROJECT_PATH/package.json" 2>/dev/null; then
            echo -e "${GREEN}  → React project detected${NC}" >&2
            extra_windows="dev"
        else
            echo -e "${GREEN}  → Generic Node.js project${NC}" >&2
            extra_windows="dev"
        fi

    # Check for Ruby/Rails project
    elif [ -f "$PROJECT_PATH/Gemfile" ]; then
        echo -e "${GREEN}✓ Detected Ruby project${NC}" >&2
        if grep -q 'rails' "$PROJECT_PATH/Gemfile" 2>/dev/null; then
            echo -e "${GREEN}  → Rails framework detected${NC}" >&2
            extra_windows="rails console"
        else
            extra_windows="dev"
        fi

    # Check for Python project
    elif [ -f "$PROJECT_PATH/requirements.txt" ] || [ -f "$PROJECT_PATH/pyproject.toml" ] || [ -f "$PROJECT_PATH/Pipfile" ]; then
        echo -e "${GREEN}✓ Detected Python project${NC}" >&2
        extra_windows="python"

    # Check for Rust project
    elif [ -f "$PROJECT_PATH/Cargo.toml" ]; then
        echo -e "${GREEN}✓ Detected Rust project${NC}" >&2
        extra_windows="cargo"

    # Check for Go project
    elif [ -f "$PROJECT_PATH/go.mod" ]; then
        echo -e "${GREEN}✓ Detected Go project${NC}" >&2
        extra_windows="go"

    # Default: just add a shell window
    else
        echo -e "${YELLOW}ℹ No specific framework detected, using default configuration${NC}" >&2
        extra_windows="shell"
    fi

    echo "$extra_windows"
}

# Detect vaults and register them
detect_vaults() {
    local vault_windows=""

    # Source monorepo detection library if available
    if [ -f "$VAULT_LIB_DIR/monorepo-detect.sh" ]; then
        # Provides detect_monorepo_type and helpers for vault auto-registration
        source "$VAULT_LIB_DIR/monorepo-detect.sh"
    fi

    # Check if this is a monorepo
    if command -v detect_monorepo_type &> /dev/null; then
        local monorepo_type=$(detect_monorepo_type "$PROJECT_PATH" 2>/dev/null)
        if [ -n "$monorepo_type" ]; then
            echo -e "${CYAN}📦 Monorepo detected: ${monorepo_type}${NC}" >&2

            # Get packages
            if command -v get_monorepo_packages &> /dev/null; then
                local packages=$(get_monorepo_packages "$PROJECT_PATH" "$monorepo_type")
                local package_count=$(echo "$packages" | wc -l | tr -d ' ')

                echo -e "${GREEN}  → Found ${package_count} package(s)${NC}" >&2

                # Ask user if they want to register packages interactively
                read -p "Register monorepo packages interactively? (y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    # Use vault monorepo command for interactive selection
                    if [ -x "$VAULT_SHIM" ]; then
                        "$VAULT_SHIM" monorepo "$PROJECT_PATH"
                    fi
                else
                    # Auto-register packages with vault content
                    echo -e "${BLUE}Auto-registering packages with vault content...${NC}" >&2
                    local registered_count=0
                    while IFS= read -r package_path; do
                        if [ -z "$package_path" ]; then continue; fi

                        # Check if package has vaultable content
                        if command -v package_has_vault_content &> /dev/null; then
                            if package_has_vault_content "$package_path"; then
                                local package_name=$(basename "$package_path")
                                echo -e "${GREEN}  → Registering: ${package_name}${NC}" >&2
                                if [ -x "$VAULT_SHIM" ]; then
                                    "$VAULT_SHIM" register "$package_path" >/dev/null 2>&1 || true
                                    registered_count=$((registered_count + 1))
                                fi
                            fi
                        fi
                    done <<< "$packages"

                    if [ $registered_count -gt 0 ]; then
                        echo -e "${GREEN}  → Auto-registered ${registered_count} package(s)${NC}" >&2
                    fi
                fi
            fi

            vault_windows="vault"
            echo "$vault_windows"
            return
        fi
    fi

    # Not a monorepo - use standard vault detection
    # Check for Agent OS or docs folders
    if [ -d "$PROJECT_PATH/.agent-os" ] || [ -d "$PROJECT_PATH/docs" ]; then
        echo -e "${GREEN}✓ Vault content detected${NC}" >&2
        # Register with unified vault manager if available
        if [ -x "$VAULT_SHIM" ]; then
            "$VAULT_SHIM" register "$PROJECT_PATH" >/dev/null 2>&1 || true
            echo -e "${GREEN}  → Registered with unified vault${NC}" >&2
        fi
        vault_windows="vault"
    fi

    # Check for other docs folders
    for docs_dir in documentation wiki notes; do
        if [ -d "$PROJECT_PATH/$docs_dir" ]; then
            echo -e "${GREEN}✓ Additional docs folder detected: $docs_dir${NC}" >&2
            if [[ "$vault_windows" != *"vault"* ]]; then
                vault_windows="vault"
            fi
            break
        fi
    done

    echo "$vault_windows"
}

# Detect project type
EXTRA_WINDOWS=$(detect_project_type)

# Detect and register vaults
VAULT_WINDOWS=$(detect_vaults)

# Combine windows
if [ -n "$VAULT_WINDOWS" ]; then
    EXTRA_WINDOWS="$EXTRA_WINDOWS $VAULT_WINDOWS"
fi

# Generate the YAML configuration
cat > "$CONFIG_FILE" << EOF
# ~/.config/tmuxinator/${SAFE_PROJECT_NAME}.yml

name: $SAFE_PROJECT_NAME
root: $PROJECT_PATH

# Project hooks - runs on project start
on_project_start: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  setup_logs "$SAFE_PROJECT_NAME"
  setup_vscode_marker "$SAFE_PROJECT_NAME"

# Run on project stop - cleanup
on_project_stop: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  cleanup_vscode_marker "$SAFE_PROJECT_NAME"

# Runs before each window starts
pre_window: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  open_vscode_once "$SAFE_PROJECT_NAME"

# Set window base-index to 1 and load tmux config
tmux_options: -f ~/.tmux.conf

# Start with the first window (claude)
startup_window: claude
startup_pane: 1
windows:
  - claude:
      root: $PROJECT_PATH
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "claude"
          claude
  - git:
      root: $PROJECT_PATH
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "git"
          lazygit
EOF

# Add project-specific windows
for window in $EXTRA_WINDOWS; do
    case $window in
        nextjs)
            cat >> "$CONFIG_FILE" << EOF
  - nextjs:
      root: $PROJECT_PATH
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "nextjs" "nextjs"
          pnpm dev 2>&1 | tee -a .logs/nextjs/nextjs.\$(date +%s).log | pnpm exec pino-pretty
EOF
            ;;
        storybook)
            cat >> "$CONFIG_FILE" << EOF
  - storybook:
      root: $PROJECT_PATH
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "storybook" "storybook"
          pnpm storybook 2>&1 | tee -a .logs/storybook/storybook.\$(date +%s).log
EOF
            ;;
        prisma)
            cat >> "$CONFIG_FILE" << EOF
  - prisma:
      root: $PROJECT_PATH
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "prisma" "prisma"
          pnpm prisma studio 2>&1 | tee -a .logs/prisma/prisma.\$(date +%s).log
EOF
            ;;
        rails)
            cat >> "$CONFIG_FILE" << EOF
  - rails:
      root: $PROJECT_PATH
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "rails" "rails"
          rails server
EOF
            ;;
        console)
            cat >> "$CONFIG_FILE" << EOF
  - console:
      root: $PROJECT_PATH
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "console"
          rails console
EOF
            ;;
        python)
            cat >> "$CONFIG_FILE" << EOF
  - python:
      root: $PROJECT_PATH
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "python"
          python
EOF
            ;;
        cargo)
            cat >> "$CONFIG_FILE" << EOF
  - cargo:
      root: $PROJECT_PATH
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "cargo"
          cargo watch -x run
EOF
            ;;
        go)
            cat >> "$CONFIG_FILE" << EOF
  - go:
      root: $PROJECT_PATH
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "go"
          go run .
EOF
            ;;
        dev)
            cat >> "$CONFIG_FILE" << EOF
  - dev:
      root: $PROJECT_PATH
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "dev" "dev"
          npm run dev 2>&1 | tee -a .logs/dev/dev.\$(date +%s).log
EOF
            ;;
        vault)
            cat >> "$CONFIG_FILE" << EOF
  - vault:
      root: $PROJECT_PATH
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "vault"
          # Show vault status for this project
                    if command -v "$VAULT_SHIM" >/dev/null 2>&1; then
                        "$VAULT_SHIM" status
          else
            echo "Vault manager not available"
          fi
          echo
          echo "Vault shortcuts:"
          echo "  Ctrl-g V - Browse all vaults"
          echo "  Ctrl-g v - Open current project vault"
          echo "  Ctrl-g D - Browse docs vaults"
EOF
            ;;
        shell|*)
            cat >> "$CONFIG_FILE" << EOF
  - shell:
      root: $PROJECT_PATH
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "shell"
          clear
EOF
            ;;
    esac
done

echo -e "${GREEN}✅ Generated config: ${BLUE}$CONFIG_FILE${NC}"
echo -e "${GREEN}✅ Windows configured: ${YELLOW}claude, git$([ -n "$EXTRA_WINDOWS" ] && echo ", $EXTRA_WINDOWS")${NC}"
echo

# Ask if user wants to edit the config
read -p "📝 Edit the config now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ${EDITOR:-vim} "$CONFIG_FILE"
fi

# Ask if user wants to start the session
echo
read -p "🚀 Start the tmuxinator session now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    tmuxinator start "$SAFE_PROJECT_NAME"
else
    echo -e "${BLUE}ℹ To start the session later, run:${NC}"
    echo -e "  ${YELLOW}tmuxinator start $SAFE_PROJECT_NAME${NC}"
    echo -e "${BLUE}ℹ Or use the session menu:${NC}"
    echo -e "  ${YELLOW}Ctrl-g T${NC} (from within tmux)"
fi
