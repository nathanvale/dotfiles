#!/usr/bin/env bash
# TaskDock Config Library
# Hierarchical configuration management

# Source common library
# shellcheck source=./common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Config file paths (in priority order)
TASKDOCK_DEFAULTS_FILE="$TASKDOCK_ROOT/config/defaults.yaml"
# TASKDOCK_USER_CONFIG is defined in common.sh

# Get repo-specific config path
get_repo_config() {
  local main_root
  main_root="$(get_main_worktree)"
  if [[ -n "$main_root" ]]; then
    echo "$main_root/$TASKDOCK_REPO_DIR_NAME/$TASKDOCK_REPO_CONFIG_NAME"
  else
    echo ""
  fi
}

# Check if repo is primed (has .taskdock/config.yaml)
is_repo_primed() {
  local repo_config
  repo_config="$(get_repo_config)"
  [[ -n "$repo_config" ]] && [[ -f "$repo_config" ]]
}

# Get config value with hierarchy: env > repo > user > defaults
# Usage: taskdock_config "key_name" ["default_value"]
taskdock_config() {
  local key="$1"
  local default="${2:-}"

  # Convert key to env var format (e.g., "ticket_prefix" -> "TASKDOCK_TICKET_PREFIX")
  local env_key
  env_key="TASKDOCK_$(echo "$key" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"

  # Check environment variable first
  if [[ -n "${!env_key:-}" ]]; then
    echo "${!env_key}"
    return 0
  fi

  # Check repo config
  local repo_config
  repo_config="$(get_repo_config)"
  if [[ -f "$repo_config" ]] && command_exists yq; then
    local value
    value=$(yq eval ".$key // \"\"" "$repo_config" 2>/dev/null)
    if [[ -n "$value" ]] && [[ "$value" != "null" ]]; then
      echo "$value"
      return 0
    fi
  fi

  # Check user config
  if [[ -f "$TASKDOCK_USER_CONFIG" ]] && command_exists yq; then
    local value
    value=$(yq eval ".$key // \"\"" "$TASKDOCK_USER_CONFIG" 2>/dev/null)
    if [[ -n "$value" ]] && [[ "$value" != "null" ]]; then
      echo "$value"
      return 0
    fi
  fi

  # Check defaults
  if [[ -f "$TASKDOCK_DEFAULTS_FILE" ]] && command_exists yq; then
    local value
    value=$(yq eval ".$key // \"\"" "$TASKDOCK_DEFAULTS_FILE" 2>/dev/null)
    if [[ -n "$value" ]] && [[ "$value" != "null" ]]; then
      echo "$value"
      return 0
    fi
  fi

  # Return default if provided
  echo "$default"
}

# Get all config as JSON (merged hierarchy)
get_merged_config() {
  local config="{}"

  # Start with defaults
  if [[ -f "$TASKDOCK_DEFAULTS_FILE" ]] && command_exists yq; then
    config=$(yq eval -o=json "$TASKDOCK_DEFAULTS_FILE" 2>/dev/null || echo "{}")
  fi

  # Merge user config
  if [[ -f "$TASKDOCK_USER_CONFIG" ]] && command_exists yq; then
    local user_config
    user_config=$(yq eval -o=json "$TASKDOCK_USER_CONFIG" 2>/dev/null || echo "{}")
    config=$(echo "$config $user_config" | jq -s '.[0] * .[1]')
  fi

  # Merge repo config
  local repo_config
  repo_config="$(get_repo_config)"
  if [[ -f "$repo_config" ]] && command_exists yq; then
    local repo_config_json
    repo_config_json=$(yq eval -o=json "$repo_config" 2>/dev/null || echo "{}")
    config=$(echo "$config $repo_config_json" | jq -s '.[0] * .[1]')
  fi

  echo "$config"
}

# Check required config keys
check_required_config() {
  local required_keys=("$@")
  local missing=()

  for key in "${required_keys[@]}"; do
    local value
    value="$(taskdock_config "$key")"
    if [[ -z "$value" ]]; then
      missing+=("$key")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    return 1
  fi
  return 0
}

# Get missing config keys
get_missing_config() {
  local required_keys=("$@")
  local missing=()

  for key in "${required_keys[@]}"; do
    local value
    value="$(taskdock_config "$key")"
    if [[ -z "$value" ]]; then
      missing+=("$key")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    printf '%s\n' "${missing[@]}"
  fi
}
