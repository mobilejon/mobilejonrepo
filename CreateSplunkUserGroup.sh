#!/bin/sh
#Create Splunk User
sudo sysadminctl -addUser splunk -fullName "Splunk" -password PASSWORD
#Create Splunk Group
sudo dscl . create /Groups/splunk


#  Unzip.sh
#  
#
#  
