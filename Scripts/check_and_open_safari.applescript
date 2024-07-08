-- Checks if a given URL is open in Safari.
-- 
-- Parameters:
--   urlToCheck (string): The URL to check.
-- 
-- Returns:
--   window: The window that contains the URL, or false if not found.
on isURLInSafari(urlToCheck)
    tell application "Safari"
        repeat with w in windows
            repeat with t in tabs of w
                if URL of t contains urlToCheck then
                    set current tab of w to t
                    return w
                end if
            end repeat
        end repeat
    end tell
    return false
end isURLInSafari

on checkAndOpenURL(theURL)
    set safariWindow to isURLInSafari(theURL)
    if safariWindow is false then
        tell application "Safari"
            set newDocument to make new document with properties {URL:theURL}
            delay 0 -- Pause for 1 second to ensure the new window is fully loaded
            activate
        end tell
    else
        tell application "System Events"
            tell process "Safari"
                set frontmost to true
            end tell
        end tell
        tell application "Safari"
            set index of safariWindow to 1
            activate
        end tell
    end if
end checkAndOpenURL

on run argv
    set theURL to item 1 of argv
    checkAndOpenURL(theURL)
end run
