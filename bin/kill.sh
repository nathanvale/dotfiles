#!/bin/bash

# remove keepalive key from...
# sudo vim /Library/LaunchAgents/com.paloaltonetworks.gp.pangpa.plist
# launchctl list | grep palo (related to GlobalProtect)
# sudo vim /private/etc/sudoers
# nathan.vale ALL=(ALL) NOPASSWD: ALL

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
