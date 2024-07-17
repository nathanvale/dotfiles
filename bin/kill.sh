#!/bin/bash

while true; do
  if pgrep -x "GlobalProtect" >/dev/null; then
    echo "GlobalProtect process found. Attempting to kill it..."
    pkill -x "GlobalProtect"
    sleep .2
    if ! pgrep -x "GlobalProtect" >/dev/null; then
      echo "GlobalProtect process successfully killed. Exiting loop..."
      break
    fi
  else
    echo "GlobalProtect process not found. Checking again..."
    sleep .2
  fi
done
