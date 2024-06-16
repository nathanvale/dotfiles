#!/bin/bash

# Quit all running applications
osascript -e 'tell application "System Events" to set quit delay of every process to 0' # Ensure quick quit
osascript -e 'tell application "System Events" to quit every application'

# Allow some time for applications to quit
sleep 5

# Remove all spaces (assuming 16 is the maximum number of spaces)
for i in {1..16}; do
  yabai -m space --destroy $i
done

# Optionally, you can create a default space and focus it
yabai -m space --create
yabai -m space --focus 1