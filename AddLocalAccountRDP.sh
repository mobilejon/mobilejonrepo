#!/bin/sh
myHost=$(hostname | /usr/bin/awk -F's-' '{print $1}'| /usr/bin/awk '{print toupper($0) }')
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -access -on -privs -ControlObserve -users $myHost
#  AddLocalAccountRDP.sh
#  
#
#  Created by Jon Towles - ADMIN on 9/29/18.
#  
