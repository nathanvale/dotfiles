#!/usr/bin/env bash
# TaskDock Version Command

set -euo pipefail

TASKDOCK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"
source "$TASKDOCK_ROOT/lib/common.sh"
source "$TASKDOCK_ROOT/lib/ui.sh"

if [[ "${TASKDOCK_OUTPUT:-human}" == "json" ]]; then
  json_response "$(jq -n --arg version "$TASKDOCK_VERSION" '{version: $version}')"
else
  print_version
fi

exit 0
