#!/bin/bash

# Function to kill GlobalProtect in an infinite loop
kill () {
  while true; do
    if pgrep -x "GlobalProtect" > /dev/null; then
      echo "GlobalProtect process found. Attempting to kill it..."
      pkill -x "GlobalProtect"
      sleep .2
    else
      echo "GlobalProtect process not found. Checking again..."
      sleep .2
    fi
  done
}

kill

