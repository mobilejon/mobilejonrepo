loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`
##sudo dscl . append  /Groups/_developer GroupMembership $loggedInUser
sudo /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -license accept
sudo /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -runFirstLaunch