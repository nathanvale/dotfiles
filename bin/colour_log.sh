#!/bin/bash

# ANSI color codes (globally scoped)
RESET='\033[0m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'

# Log levels (globally scoped)
INFO="INFO"
WARNING="WARNING"
ERROR="ERROR"

# Log function
log() {
    local level=$1
    local message=$2
    local color

    case $level in
    $INFO)
        color=$GREEN
        ;;
    $WARNING)
        color=$YELLOW
        ;;
    $ERROR)
        color=$RED
        ;;
    *)
        color=$RESET
        level="UNKNOWN"
        message="Unknown log level: $1. Message: $2"
        ;;
    esac

    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message${RESET}"
}

