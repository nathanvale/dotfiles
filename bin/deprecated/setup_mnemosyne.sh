#!/bin/bash

# 🧠 Mnemosyne Project Setup Script
# Sets up a new mnemosyne project with tmuxinator configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default project path
PROJECT_PATH="$HOME/code/mnemosyne"

# Check if project path is provided
if [ $# -eq 1 ]; then
    PROJECT_PATH="$1"
fi

print_status "Setting up mnemosyne project at: $PROJECT_PATH"

# Create project directory if it doesn't exist
if [ ! -d "$PROJECT_PATH" ]; then
    print_status "Creating project directory: $PROJECT_PATH"
    mkdir -p "$PROJECT_PATH"
fi

cd "$PROJECT_PATH"

# Create .logs directory
print_status "Creating .logs directory"
mkdir -p .logs

# Copy .envrc template if it doesn't exist
if [ ! -f ".envrc" ]; then
    print_status "Creating .envrc file"
    if [ -f "$HOME/.config/dotfiles/templates/.envrc" ]; then
        cp "$HOME/.config/dotfiles/templates/.envrc" .
    else
        # Fallback inline creation
        cat > .envrc << 'EOF'
# .envrc for mnemosyne project
# This file enables direnv to automatically load environment variables

# Load .env.development if it exists
if [ -f .env.development ]; then
  use dotenv .env.development
fi

# Load .env.local if it exists (for local overrides)
if [ -f .env.local ]; then
  use dotenv .env.local
fi

# Add any additional environment setup here
# Example: export NODE_ENV=development
EOF
    fi
    print_success "Created .envrc file"
else
    print_warning ".envrc already exists, skipping"
fi

# Update .gitignore with logs directory
if [ -f ".gitignore" ]; then
    if ! grep -q ".logs/" .gitignore; then
        print_status "Adding .logs/ to .gitignore"
        echo -e "\n# Logs directory created by tmuxinator mnemosyne session\n.logs/" >> .gitignore
        print_success "Added .logs/ to .gitignore"
    else
        print_warning ".logs/ already in .gitignore, skipping"
    fi
else
    print_status "Creating .gitignore with logs directory"
    echo -e "# Logs directory created by tmuxinator mnemosyne session\n.logs/" > .gitignore
    print_success "Created .gitignore with .logs/ entry"
fi

# Allow direnv if it's installed
if command -v direnv >/dev/null 2>&1; then
    print_status "Setting up direnv"
    direnv allow
    print_success "direnv configured"
else
    print_warning "direnv not found. Install with: brew install direnv"
fi

# Check if tmuxinator is installed
if ! command -v tmuxinator >/dev/null 2>&1; then
    print_warning "tmuxinator not found. Install with: gem install tmuxinator"
fi

# Instructions
print_success "✅ Mnemosyne project setup complete!"
echo
print_status "Next steps:"
echo "1. Install dependencies: pnpm install"
echo "2. Set up your .env.development file with environment variables"
echo "3. Start the development environment: tmuxinator start mnemosyne"
echo
print_status "Tmuxinator windows will be:"
echo "  1. claude    - claude-code (Claude Code CLI)"
echo "  2. dev       - pnpm dev (with logging)"
echo "  3. git       - lazygit"
echo "  4. logs      - lnav .logs"
echo "  5. storybook - pnpm storybook"
echo "  6. prisma    - pnpm prisma studio"
echo
print_status "VS Code will auto-launch when starting the tmuxinator session"
