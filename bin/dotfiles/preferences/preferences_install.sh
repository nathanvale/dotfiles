#!/bin/bash
# preferences_install.sh - Bridge script for macOS preferences
#
# Called by install.sh to apply macOS system preferences.

set -e

DOTFILES="$(cd "$(dirname "$0")/../../.." && pwd)"

"$DOTFILES/bin/system/macos/macos_preferences_manage.sh" --set
