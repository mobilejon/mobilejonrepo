#!/bin/sh
##Copy Deployment File##
cp /usr/local/mgsft_rollout_response /var/tmp/mgsft_rollout_response
##Copy Certificates##
cp /usr/local/mgsft_rollout_cert /var/tmp/mgsft_rollout_cert
##Install Flexera##
sudo installer -verbose -pkg /usr/local/ManageSoft.pkg -target /
#  FlexeraDeployment.sh
#  
#  
