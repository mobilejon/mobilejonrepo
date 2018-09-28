#!/bin/sh
# Variables
myHost=$(hostname | /usr/bin/awk -F's-' '{print $1}')
cert=`security find-certificate -c $myHost -Z | grep SHA | awk '{print $3}'`
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`
#Create .anyconnect config file
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<AnyConnectPreferences>
<DefaultUser>$loggedInUser</DefaultUser>
<DefaultSecondUser></DefaultSecondUser>
<ClientCertificateThumbprint>$cert</ClientCertificateThumbprint>
<ServerCertificateThumbprint></ServerCertificateThumbprint>
<DefaultHostName>vpn.test.com</DefaultHostName>
<DefaultHostAddress>vpn.test.com</DefaultHostAddress>
<DefaultGroup>VPNGROUP</DefaultGroup>
<ProxyHost></ProxyHost>
<ProxyPort></ProxyPort>
<SDITokenType>none</SDITokenType>
<ControllablePreferences></ControllablePreferences>
</AnyConnectPreferences>" > /Users/$loggedInUser/.anyconnect

#  PopulateCert.sh
#  
#
#  Created by Jon Towles on 5/7/18.
#  
