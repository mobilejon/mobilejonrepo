#!/bin/sh
myHost=$(hostname -s | /usr/bin/awk '{print toupper($0) }')
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -access -on -privs -ControlObserve -users $myHost
#  AddLocalAccountRDP.sh
