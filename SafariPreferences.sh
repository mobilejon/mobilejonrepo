#!/bin/sh
HomePage='https://mobile-jon.com'

User="$(defaults read '/Library/Application Support/AirWatch/Data/CustomAttributes/CustomAttributes' 'EnrollmentUser')"


# Set Safari Homepage

defaults write /Users/$User/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist HomePage -string $HomePage
defaults write /Users/$User/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist NewWindowBehavior -int 0
defaults write /Users/$User/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist NewTabBehavior -int 0
chown $User /Users/$User/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist

#Flush Preference Cache
killall cfprefsd
#  SafariPreferences.sh
#  
#  
