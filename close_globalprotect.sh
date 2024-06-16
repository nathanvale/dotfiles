#!/bin/bash
while true; do
    if pgrep -x "GlobalProtect" > /dev/null
    then
        pkill -x "GlobalProtect"
    fi
    sleep 8
done

