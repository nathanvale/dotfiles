#!/usr/bin/env bash
# TaskDock Git Library
# Git operations and provider detection

# Source common library
# shellcheck source=./common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Detect git provider (github or azure)
detect_git_provider() {
  local remote_url
  remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")

  if [[ "$remote_url" =~ github\.com ]]; then
    echo "github"
  elif [[ "$remote_url" =~ dev\.azure\.com ]] || [[ "$remote_url" =~ visualstudio\.com ]]; then
    echo "azure"
  else
    echo "unknown"
  fi
}

# Get current branch
get_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""
}

# Check if branch exists
branch_exists() {
  local branch="$1"
  git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null
}

# Check if remote branch exists
remote_branch_exists() {
  local branch="$1"
  git ls-remote --heads origin "$branch" 2>/dev/null | grep -q "$branch"
}

# Check if branch is merged into main/master
is_branch_merged() {
  local branch="$1"
  local main_branch="${2:-main}"

  # Check if main branch exists, fall back to master
  if ! branch_exists "$main_branch"; then
    main_branch="master"
  fi

  git branch --merged "$main_branch" | grep -q "^[* ]*${branch}$"
}

# Get git worktree list as JSON
get_worktrees_json() {
  local worktrees=()

  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      local path branch commit
      path=$(echo "$line" | awk '{print $1}')
      branch=$(echo "$line" | awk '{print $3}' | tr -d '[]')
      commit=$(echo "$line" | awk '{print $2}')

      worktrees+=("$(jq -n \
        --arg path "$path" \
        --arg branch "$branch" \
        --arg commit "$commit" \
        '{path: $path, branch: $branch, commit: $commit}')")
    fi
  done < <(git worktree list --porcelain 2>/dev/null | grep -E "^worktree |^HEAD |^branch " | paste -d' ' - - -)

  printf '%s\n' "${worktrees[@]}" | jq -s '.'
}

# Check if working tree is clean
is_working_tree_clean() {
  [[ -z "$(git status --porcelain 2>/dev/null)" ]]
}

# Get repo metadata as JSON
get_repo_metadata() {
  local repo_root
  repo_root="$(get_repo_root)"

  if [[ -z "$repo_root" ]]; then
    echo "{}"
    return
  fi

  local repo_name
  repo_name="$(get_repo_name "$repo_root")"

  local current_branch
  current_branch="$(get_current_branch)"

  local provider
  provider="$(detect_git_provider)"

  local is_clean
  is_clean="$(is_working_tree_clean && echo "true" || echo "false")"

  jq -n \
    --arg root "$repo_root" \
    --arg name "$repo_name" \
    --arg branch "$current_branch" \
    --arg provider "$provider" \
    --argjson clean "$is_clean" \
    '{
      root: $root,
      name: $name,
      currentBranch: $branch,
      provider: $provider,
      isClean: $clean
    }'
}
