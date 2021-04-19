#!/bin/sh
# Variables
User="$(defaults read '/Library/Application Support/AirWatch/Data/CustomAttributes/CustomAttributes' 'EnrollmentUser')"
/usr/bin/defaults write /Users/$User/Library/Preferences/com.apple.systemuiserver.plist menuExtras -array \ "/System/Library/CoreServices/Menu Extras/AirPort.menu" \
"/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
"/System/Library/CoreServices/Menu Extras/Clock.menu" \
"/System/Library/CoreServices/Menu Extras/Displays.menu" \
"/System/Library/CoreServices/Menu Extras/Volume.menu" \
"/System/Library/CoreServices/Menu Extras/Battery.menu"
chmod 755 /Users/$User/Library/Preferences/com.apple.systemuiserver.plist
#  AddtoMenuBar.sh
#  
#
#  Created by Jon Towles on 5/7/18.
#  
