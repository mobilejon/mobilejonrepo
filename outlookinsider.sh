#!/bin/sh
# Variables
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`
loggedInUserHome=`dscl . -read /Users/$loggedInUser NFSHomeDirectory | awk '{print $NF}'`

# backup current file
/bin/cp "/Users/$loggedInUser/Library/Preferences/com.microsoft.autoupdate2.plist" "/Users/$loggedInUser/Library/Preferences/com.microsoft.autoupdate2.plist.backup"
/bin/echo "Preference archived as: /Users/$loggedInUser/Library/Preferences/com.microsoft.autoupdate2.plist.backup"

/usr/bin/defaults write /Users/$loggedInUser/Library/Preferences/com.microsoft.autoupdate2.plist ChannelName InsiderFast
/bin/echo "Channel Name set to InsiderFast for $loggedInUser"
/usr/bin/defaults write /Users/$loggedInUser/Library/Preferences/com.microsoft.autoupdate2.plist HowToCheck AutomaticDownload
/bin/echo "Updates will now be automatically downloaded"
/usr/sbin/chown $loggedInUser /Users/$loggedInUser/Library/Preferences/com.microsoft.autoupdate2.plist

# Respawn cfprefsd to load new preferences
/usr/bin/killall cfprefsd

else

/bin/echo "Microsoft Auto Update Preferences not found for $loggedInUser"

fi
#  OutlookInsider.sh
#  
#
#  Created by jonathan towles on 10/5/20.
#  
