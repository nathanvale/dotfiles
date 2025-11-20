#!/bin/bash
# Detect git remote provider type
# Returns: github, azure, gitlab, or unknown

REMOTE_URL=$(git remote get-url origin 2>/dev/null)

if [ -z "$REMOTE_URL" ]; then
  echo "unknown"
  exit 0
fi

if [[ "$REMOTE_URL" == *"dev.azure.com"* ]] || [[ "$REMOTE_URL" == *"visualstudio.com"* ]]; then
  echo "azure"
elif [[ "$REMOTE_URL" == *"github.com"* ]]; then
  echo "github"
elif [[ "$REMOTE_URL" == *"gitlab.com"* ]]; then
  echo "gitlab"
else
  echo "unknown"
fi
