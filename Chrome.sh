#!/bin/sh
# Variables
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`
loggedInUserHome=`dscl . -read /Users/$loggedInUser NFSHomeDirectory | awk '{print $NF}'`
tld="*.test.com"



# Google Chrome
/bin/echo "*** Enable single sign-on in Google Chrome for $loggedInUser ***"
/bin/echo "Quit all Chrome-related processes"
/usr/bin/pkill -l -U ${loggedInUser} Chrome

if [ -f "/Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist" ]; then

# backup current file
/bin/cp "/Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist" "/Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist.backup"
/bin/echo "Preference archived as: /Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist.backup"

/usr/bin/defaults write /Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist AuthNegotiateDelegateWhitelist $tld
/bin/echo "AuthNegotiateDelegateWhitelist set to $tld for $loggedInUser"
/usr/bin/defaults write /Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist AuthServerWhitelist $tld
/bin/echo "AuthServerWhitelist set to $tld for $loggedInUser"
/usr/bin/defaults write /Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist AutoSelectCertificateForUrls -array-add -string "{\"pattern\":\"https://cas-aws.vmwareidentity.com\",\"filter\":{}}"
/usr/sbin/chown $loggedInUser /Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist

# Respawn cfprefsd to load new preferences
/usr/bin/killall cfprefsd

else

/bin/echo "Google preference not found for $loggedInUser"

fi
