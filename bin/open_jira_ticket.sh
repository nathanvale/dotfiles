#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Jira Ticket
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.argument1 { "type": "text", "placeholder": "Placeholder" }

# Documentation:
# @raycast.author Nathan Vale

# Extract the last part of the input string, assuming it is in the form 'https://originenergy.atlassian.net/browse/CAS-653'
url="$1"
issue_code=$(echo "$url" | awk -F/ '{print $NF}')

https://ap-southeast-2.console.aws.amazon.com/codesuite/codecommit/repositories/zero-develop-frontend-home/browse?region=ap-southeast-2# if no argument is provided, open the Jira board
if [ -z "$1" ]; then
    open "https://originenergy.atlassian.net/secure/RapidBoard.jspa?rapidView=1"
else
    open "https://originenergy.atlassian.net/browse/${issue_code}"
fi
