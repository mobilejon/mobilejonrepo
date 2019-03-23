#!/bin/sh
##Kill the Current Hub Application##
pkill -f /Applications/Intelligent\ Hub.app/
##Delete the AW Folder##
sudo rm -rf "/Library/Application Support/AirWatch"
##Kill the Hub Application again just in case##
pkill -f /Applications/Intelligent\ Hub.app/
##Remove the App from the Applications Folder##
sudo rm -rf "/Applications/Intelligent Hub.app"
##Download the latest Intelligent Hub from the Cloud Endpoint##
sudo curl https://storage.googleapis.com/getwsone-com-prod/downloads/VMwareWorkspaceONEIntelligentHub.pkg --output /usr/local/WS1.pkg
##Reinstall the Intelligent Hub##
sudo installer -pkg /usr/local/WS1.pkg -target /
