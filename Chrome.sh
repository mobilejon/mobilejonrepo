#!/bin/sh
# Variables
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`
loggedInUserHome=`dscl . -read /Users/$loggedInUser NFSHomeDirectory | awk '{print $NF}'`
tld="*.test.com"
# Google Chrome
# backup current file
/bin/cp "/Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist" "/Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist.backup"
/usr/bin/defaults write /Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist AuthNegotiateDelegateWhitelist $tld
/usr/bin/defaults write /Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist AuthServerWhitelist $tld
/usr/sbin/chown $loggedInUser /Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist
# Respawn cfprefsd to load new preferences
/usr/bin/killall cfprefsd

