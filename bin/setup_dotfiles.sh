#!/bin/bash

# yabai uses the macOS Mach APIs to inject code into Dock.app; this requires
# elevated (root) privileges. You can configure your user to execute yabai
# --load-sa as the root user without having to enter a password. To do this,
# we add a new configuration entry that is loaded by /etc/sudoers.
# https://tinyurl.com/27vdt398

# dss
# echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) |
# cut -d " " -f 1) $(which yabai) --load-sa" | sudo tee
# /private/etc/sudoers.d/yabai

# curl -L https://iterm2.com/shell_integration/fish \
# -o ~/.iterm2_shell_integration.fish

# Activity Monitor
# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0
# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
# Set sort direction to descending in Activity Monitor
defaults write com.apple.ActivityMonitor SortDirection -int 0

# Apple Global Domain
# Enable Dark Mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
# Enable full keyboard access for all controls (e.g., enable Tab in modal
# dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2
# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
# Set a short delay until key repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 10
# Disable automatic capitalization as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# Disable smart dashes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
# Disable automatic period substitution as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
# Disable smart quotes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
# Speed up window resize animations
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true
# Enable WebKit developer tools
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Bluetooth Audio
# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Crash Reporter
# Disable the crash reporter
defaults write com.apple.CrashReporter DialogType -string "none"

# Desktop Services
# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disk Images
# Automatically open a new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
# Disable disk image verification
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Dock
# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true
# Speed up Dock auto-hide/show animation
defaults write com.apple.dock autohide-time-modifier -float 0.001
# Enable spring loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true
# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1
# Disable animation when opening applications from the Dock
defaults write com.apple.dock launchanim -bool false
# Change minimize/maximize window effect to scale
defaults write com.apple.dock mineffect -string "scale"
# Minimize windows into their application’s icon
defaults write com.apple.dock minimize-to-application -bool true
# Enable highlight hover effect for the grid view of a stack (Dock)
defaults write com.apple.dock mouse-over-hilite-stack -bool true
# Clear all default app icons from the Dock
defaults write com.apple.dock persistent-apps -array
# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool true
# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true
# Disable the Launchpad gesture (pinch with thumb and three fingers)
defaults write com.apple.dock showLaunchpadGestureEnabled -int 0
# Show only open applications in the Dock
defaults write com.apple.dock static-only -bool true
# Set the icon size of Dock items to 16 pixels
defaults write com.apple.dock tilesize -int 16
# Do not display recent apps in the Dock
defaults write com.apple.dock "show-recents" -bool false
# Keep the Spaces arrangement in the order it was set
defaults write com.apple.dock "mru-spaces" -bool false
# Configure hot corners: Top left screen corner → Desktop
defaults write com.apple.dock wvous-tl-corner -int 4
defaults write com.apple.dock wvous-tl-modifier -int 1048576
# Configure hot corners: Top right screen corner → Desktop
defaults write com.apple.dock wvous-tr-corner -int 4
defaults write com.apple.dock wvous-tr-modifier -int 1048576
# Configure hot corners: Bottom left screen corner → Start screen saver
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 1048576
# Configure hot corners: Bottom right screen corner → Put display to sleep
defaults write com.apple.dock wvous-br-corner -int 10
defaults write com.apple.dock wvous-br-modifier -int 1048576

# Finder
# Search the current folder by default when performing a search
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Expand General, Open With, and Privileges panes in Finder Info windows
defaults write com.apple.finder FXInfoPanesExpanded -dict \
	General -bool true \
	OpenWith -bool true \
	Privileges -bool true
# Use column view in all Finder windows by default
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
# Set Desktop as the default location for new Finder windows
defaults write com.apple.finder NewWindowTarget -string "PfLo" &&
	defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"
# Automatically open a new Finder window when a removable disk is mounted
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true
# Enable quitting via ⌘ + Q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool false
# Show icons for external hard drives, servers, and removable media on the
# desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Allow text selection in Quick Look
defaults write com.apple.finder QLEnableTextSelection -bool true

# Help Viewer
# Set Help Viewer windows to non-floating mode
defaults write com.apple.helpviewer DevMode -bool true

# Mail
# Copy email addresses as `foo@example.com` instead of `Foo Bar
# <foo@example.com>` in Mail.app
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# Printing
# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Safari
# Uncomment and set these settings if needed
# # Disable sending search queries to Apple
# defaults write com.apple.Safari UniversalSearchEnabled -bool false
# defaults write com.apple.Safari SuppressSearchSuggestions -bool true
# # Enable continuous spellchecking
# defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true
# # Disable auto-correct
# defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool
# false
# # Set Safari’s home page to `about:blank` for faster loading
# defaults write com.apple.Safari HomePage -string "about:blank"
# # Prevent Safari from opening ‘safe’ files automatically after
# downloading
# defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
# # Allow hitting the Backspace key to go to the previous page in history
# defaults write com.apple.Safari
# com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled
# -bool true
# # Enable Safari’s debug menu
# defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
# # Make Safari’s search banners default to Contains instead of Starts With
# defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false
# # Remove useless icons from Safari’s bookmarks bar
# defaults write com.apple.Safari ProxiesInBookmarksBar "()"
# # Enable the Develop menu and the Web Inspector in Safari
# defaults write com.apple.Safari IncludeDevelopMenu -bool true
# defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey
# -bool true
# defaults write com.apple.Safari
# com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled
# -bool true
# # Warn about fraudulent websites
# defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true
# # Disable plug-ins
# defaults write com.apple.Safari WebKitPluginsEnabled -bool false
# defaults write com.apple.Safari
# com.apple.Safari.ContentPageGroupIdentifier.WebKit2PluginsEnabled -bool
# false
# # Disable Java
# defaults write com.apple.Safari WebKitJavaEnabled -bool false
# defaults write com.apple.Safari
# com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled -bool false
# # Block pop-up windows
# defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically
# -bool false
# defaults write com.apple.Safari
# com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically
# -bool false
# # Disable auto-playing video
# defaults write com.apple.Safari WebKitMediaPlaybackAllowsInline -bool false
# defaults write com.apple.SafariTechnologyPreview
# WebKitMediaPlaybackAllowsInline -bool false
# defaults write com.apple.Safari
# com.apple.Safari.ContentPageGroupIdentifier.WebKit2AllowsInlineMediaPlayback
# -bool false
# defaults write com.apple.SafariTechnologyPreview
# com.apple.Safari.ContentPageGroupIdentifier.WebKit2AllowsInlineMediaPlayback
# -bool false
# # Enable “Do Not Track”
# defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true
# # Update extensions automatically
# defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool
# true
# # Show the full URL in the address bar (note: this still hides the scheme)
# defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Screenshots
# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"
# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Software Update
# Enable the automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
# Check for software updates daily, not just once per week
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
# Automatically install System data files & security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
# Automatically download apps purchased on other Macs
defaults write com.apple.SoftwareUpdate ConfigDataInstall -int 1
# Turn on app auto-update
defaults write com.apple.commerce AutoUpdate -bool true
# Disallow the App Store to reboot machine on macOS updates
defaults write com.apple.commerce AutoUpdateRestartRequired -bool false

# Spotlight
# Uncomment the following lines if needed to hide Spotlight tray icon
# sudo chmod 600
# /System/Library/CoreServices/Search.bundle/Contents/MacOS/Search
# sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array
# "/Volumes"

# Terminal
# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# Time Machine
# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Universal Access
# Uncomment and set these settings if needed
# # Minimize the motion effects across macOS, including transitions when
# switching between spaces (desktops)
# defaults write com.apple.universalaccess reduceMotion -bool true
# # Use scroll gesture with the Ctrl (^) modifier key to zoom
# defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool
# true
# defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int
# 262144

# Remove duplicates in the "Open With" menu
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# Show the ~/Library folder
chflags nohidden ~/Library

# Kill affected applications
killall Dock
killall Finder
