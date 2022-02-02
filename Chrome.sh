#!/bin/sh
# Variables

loggedInUser="$(defaults read '/Library/Application Support/AirWatch/Data/CustomAttributes/CustomAttributes' 'EnrollmentUser')"
## Script

/bin/echo "*** Enable single sign-on in Google Chrome for $loggedInUser ***"
/bin/echo "Quit all Chrome-related processes"
/usr/bin/pkill -l -U ${loggedInUser} Chrome

if [ -f "/Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist" ]; then

# backup current file

/bin/cp "/Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist" "/Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist.backup"
/bin/echo "Preference archived as: /Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist.backup"
security set-identity-preference -c $loggedInUser -s cas-aws.vmwareidentity.com
/usr/bin/defaults write /Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist AutoSelectCertificateForUrls -array -string "{\"pattern\":\"https://cas-aws.vidmpreview.com\",\"filter\":{\"SUBJECT\":{\"CN\":\"$loggedInUser\"}}}"
/usr/sbin/chown $loggedInUser /Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist

# Respawn cfprefsd to load new preferences
/usr/bin/killall cfprefsd

else

/bin/echo "Google preference not found for $loggedInUser"

fi
