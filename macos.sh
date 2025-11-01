#!/usr/bin/env bash

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

sudo -v

_keep_sudo() {
  local parent_pid="$1"
  while true; do
    # Refresh sudo timestamp; ignore any errors
    sudo -n true 2>/dev/null || true
    sleep 60
    # If the parent process no longer exists, exit the loop
    if ! kill -0 "${parent_pid}" 2>/dev/null; then
      exit 0
    fi
  done
}

_keep_sudo $$ & SUDO_PID=$!
trap 'kill "${SUDO_PID}" 2>/dev/null || true' EXIT

# Load modular config scripts
# Any script in macos.d/ that ends with .sh will be sourced.
SCRIPTS_DIR="$(dirname "${BASH_SOURCE[0]}")/macos.d"
if [ -d "${SCRIPTS_DIR}" ]; then
  for f in "${SCRIPTS_DIR}"/*.sh; do
    # shellcheck disable=SC1090
    [ -r "$f" ] && source "$f"
  done
fi

# Disable the sound effects on boot
# sudo nvram SystemAudioVolume=" "

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Prevent Photos from opening automatically when devices are plugged in
# (also present in some extracted scripts; kept here for compatibility)
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

# Always show scrollbars
#defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
# Possible values: `WhenScrolling`, `Automatic` and `Always`

# Remove duplicates in the “Open With” menu
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# Disable automatic capitalization as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes as they’re annoying when typing code
# defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution as it’s annoying when typing code
# defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes as they’re annoying when typing code
# defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to the desktop
defaults write com.apple.screencapture location -string "${HOME}/Desktop"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true


# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Disable Time Machine backups
hash tmutil &> /dev/null && sudo tmutil disable

# Enable the debug menu in Disk Utility
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true

# Auto-play videos when opened with QuickTime Player
defaults write com.apple.QuickTimePlayerX MGPlayMovieOnOpen -bool true

# Disable Spotlight
sudo mdutil -a -i off

# Kill affected applications
for app in "Activity Monitor" \
	"Calendar" \
	"Dock" \
	"Finder" \
	"Google Chrome Canary" \
	"Google Chrome" \
	"Mail" \
	"Photos" \
	"Safari"; do
	killall "${app}" &> /dev/null
done
