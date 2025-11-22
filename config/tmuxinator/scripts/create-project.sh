#!/bin/bash
# ~/code/dotfiles/config/tmuxinator/scripts/create-project.sh
# Generator script for creating new tmuxinator projects from templates

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

TMUXINATOR_DIR="$HOME/.config/tmuxinator"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_usage() {
    cat <<EOF
${BLUE}Tmuxinator Project Generator${NC}

${GREEN}Usage:${NC}
    $0 <project_name> [template_type] [project_root]

${GREEN}Arguments:${NC}
    project_name    Name of the tmuxinator project to create
    template_type   Type of template to use (default: basic)
                    Options: basic, standard, fullstack, ai, dual-ai
    project_root    Root directory for the project (default: ~/code/<project_name>)

${GREEN}Template Types:${NC}
    ${YELLOW}basic${NC}       Claude + Git (2 windows)
    ${YELLOW}standard${NC}    Claude + Git + Shell (3 windows)
    ${YELLOW}fullstack${NC}   Claude + Git + Dev + Vault (4 windows)
    ${YELLOW}ai${NC}          Multi-AI agents (Claude + Gemini + Codex) + tools (4+ windows)
    ${YELLOW}dual-ai${NC}     Dual AI agents (Claude + Gemini) + tools (4 windows)

${GREEN}Examples:${NC}
    # Create basic project
    $0 my-cli-tool

    # Create fullstack project with custom root
    $0 my-webapp fullstack ~/projects/my-webapp

    # Create AI-powered project
    $0 ai-experiment ai ~/experiments/ai-test

${GREEN}Generated file location:${NC}
    $TMUXINATOR_DIR/<project_name>.yml

${GREEN}Quick start:${NC}
    tmuxinator start <project_name>
EOF
}

error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}$1${NC}"
}

info() {
    echo -e "${BLUE}$1${NC}"
}

warning() {
    echo -e "${YELLOW}$1${NC}"
}

# ============================================================================
# TEMPLATE GENERATION FUNCTIONS
# ============================================================================

generate_basic_template() {
    local project_name="$1"
    local project_root="$2"

    cat <<EOF
# ~/.config/tmuxinator/${project_name}.yml

name: ${project_name}
root: ${project_root}

# Project hooks
on_project_start: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  setup_vscode_marker "${project_name}"

on_project_stop: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  cleanup_vscode_marker "${project_name}"

pre_window: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  open_vscode_once "${project_name}"

# Tmux configuration
tmux_options: -f ~/.tmux.conf
startup_window: claude
startup_pane: 1

# Windows
windows:
  - claude:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "claude"
          claude

  - git:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "git"
          lazygit
EOF
}

generate_standard_template() {
    local project_name="$1"
    local project_root="$2"

    cat <<EOF
# ~/.config/tmuxinator/${project_name}.yml

name: ${project_name}
root: ${project_root}

# Project hooks
on_project_start: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  setup_vscode_marker "${project_name}"

on_project_stop: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  cleanup_vscode_marker "${project_name}"

pre_window: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  open_vscode_once "${project_name}"

# Tmux configuration
tmux_options: -f ~/.tmux.conf
startup_window: claude
startup_pane: 1

# Windows
windows:
  - claude:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "claude"
          claude

  - git:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "git"
          lazygit

  - shell:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "shell"
          clear
EOF
}

generate_fullstack_template() {
    local project_name="$1"
    local project_root="$2"

    cat <<EOF
# ~/.config/tmuxinator/${project_name}.yml

name: ${project_name}
root: ${project_root}

# Project hooks
on_project_start: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  setup_vscode_marker "${project_name}"

on_project_stop: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  cleanup_vscode_marker "${project_name}"

pre_window: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  open_vscode_once "${project_name}"

# Tmux configuration
tmux_options: -f ~/.tmux.conf
startup_window: claude
startup_pane: 1

# Windows
windows:
  - claude:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "claude"
          claude

  - git:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "git"
          lazygit

  - dev:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "dev"
          npm run dev

  - vault:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "vault"
          if command -v "\$HOME/code/dotfiles/bin/vault/vault" >/dev/null 2>&1; then
            "\$HOME/code/dotfiles/bin/vault/vault" status
          else
            echo "Vault manager not available"
          fi
          echo
          echo "Vault shortcuts:"
          echo "  Ctrl-g V - Browse all vaults"
          echo "  Ctrl-g v - Open current project vault"
          echo "  Ctrl-g D - Browse docs vaults"
EOF
}

generate_ai_template() {
    local project_name="$1"
    local project_root="$2"

    cat <<EOF
# ~/.config/tmuxinator/${project_name}.yml

name: ${project_name}
root: ${project_root}

# Project hooks
on_project_start: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  setup_vscode_marker "${project_name}"

on_project_stop: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  cleanup_vscode_marker "${project_name}"

pre_window: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  open_vscode_once "${project_name}"

# Tmux configuration
tmux_options: -f ~/.tmux.conf
startup_window: ai-agents
startup_pane: 1

# Windows
windows:
  - ai-agents:
      layout: tiled
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "claude"
          claude
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "gemini"
          echo "🔷 Gemini AI Agent"
          echo "Replace with: gemini"
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "codex"
          echo "🔶 Codex AI Agent"
          echo "Replace with: codex"
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "shell"
          clear

  - git:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "git"
          lazygit

  - dev:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "dev"
          npm run dev

  - vault:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "vault"
          if command -v "\$HOME/code/dotfiles/bin/vault/vault" >/dev/null 2>&1; then
            "\$HOME/code/dotfiles/bin/vault/vault" status
          else
            echo "Vault manager not available"
          fi
          echo
          echo "Vault shortcuts:"
          echo "  Ctrl-g V - Browse all vaults"
          echo "  Ctrl-g v - Open current project vault"
          echo "  Ctrl-g D - Browse docs vaults"
EOF
}

generate_dual_ai_template() {
    local project_name="$1"
    local project_root="$2"

    cat <<EOF
# ~/.config/tmuxinator/${project_name}.yml

name: ${project_name}
root: ${project_root}

# Project hooks
on_project_start: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  setup_vscode_marker "${project_name}"

on_project_stop: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  cleanup_vscode_marker "${project_name}"

pre_window: |
  source ~/.config/tmuxinator/scripts/common-setup.sh
  open_vscode_once "${project_name}"

# Tmux configuration
tmux_options: -f ~/.tmux.conf
startup_window: ai-agents
startup_pane: 1

# Windows
windows:
  - ai-agents:
      layout: main-vertical
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "claude"
          claude
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "gemini"
          echo "🔷 Gemini AI Agent"
          echo "Replace with: gemini"

  - git:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "git"
          lazygit

  - dev:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "dev"
          npm run dev

  - vault:
      panes:
        - |
          source ~/.config/tmuxinator/scripts/common-setup.sh
          pane_setup "vault"
          if command -v "\$HOME/code/dotfiles/bin/vault/vault" >/dev/null 2>&1; then
            "\$HOME/code/dotfiles/bin/vault/vault" status
          else
            echo "Vault manager not available"
          fi
          echo
          echo "Vault shortcuts:"
          echo "  Ctrl-g V - Browse all vaults"
          echo "  Ctrl-g v - Open current project vault"
          echo "  Ctrl-g D - Browse docs vaults"
EOF
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

main() {
    # Parse arguments
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        print_usage
        exit 0
    fi

    local project_name="$1"
    local template_type="${2:-basic}"
    local project_root="${3:-$HOME/code/$project_name}"

    # Validate project name
    if [ -z "$project_name" ]; then
        error "Project name cannot be empty"
    fi

    # Check if project already exists
    local output_file="$TMUXINATOR_DIR/${project_name}.yml"
    if [ -f "$output_file" ]; then
        warning "Project '${project_name}' already exists at: $output_file"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Cancelled."
            exit 0
        fi
    fi

    # Generate template based on type
    info "Creating ${template_type} project: ${project_name}"
    info "Root directory: ${project_root}"
    echo

    case "$template_type" in
        basic)
            generate_basic_template "$project_name" "$project_root" > "$output_file"
            ;;
        standard)
            generate_standard_template "$project_name" "$project_root" > "$output_file"
            ;;
        fullstack)
            generate_fullstack_template "$project_name" "$project_root" > "$output_file"
            ;;
        ai)
            generate_ai_template "$project_name" "$project_root" > "$output_file"
            ;;
        dual-ai)
            generate_dual_ai_template "$project_name" "$project_root" > "$output_file"
            ;;
        *)
            error "Unknown template type: $template_type\nValid options: basic, standard, fullstack, ai, dual-ai"
            ;;
    esac

    success "✅ Created: $output_file"
    echo
    info "📝 Template: ${template_type}"
    info "📂 Root: ${project_root}"
    echo
    success "🚀 Start your project with:"
    echo "   tmuxinator start ${project_name}"
    echo
    info "💡 Customize your project by editing:"
    echo "   ${output_file}"
}

main "$@"
