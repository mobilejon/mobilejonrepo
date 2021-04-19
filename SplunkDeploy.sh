#!/bin/sh
#!/bin/sh
cd /opt/;export SPLUNK_HOME=/opt/splunkforwarder
sudo tar xvzf /tmp/splunkforwarder*.tgz
cd ./splunkforwarder/

#Kill splunkd if running
PID=$(pgrep splunkd)

if [ ! -z "$PID" ]
    then
        killall splunkd
fi

#General Deployment Client App#


# Splunk First-Time-Run (FTR)


sleep 3
# NOTE: This part MUST BE RUN AS root (or sudo)!
# NOTE: If running splunk as non-root, add "-user splunk" to the argument list of "enable boot-start"
sudo cp /usr/local/user-seed.conf "${SPLUNK_HOME}"/etc/system/local/user-seed.conf
sudo cp /usr/local/deploymentclient.conf "${SPLUNK_HOME}"/etc/system/local/deploymentclient.conf
sudo chown -R splunk ${SPLUNK_HOME}
sudo -u splunk ${SPLUNK_HOME}/bin/splunk start --accept-license --auto-ports --no-prompt --answer-yes
sudo "${SPLUNK_HOME}"/bin/splunk enable boot-start -user splunk


sleep 3

sudo launchctl load /Library/LaunchDaemons/com.splunk.plist

# Ownership probably does not need to be changed because
# probably script is being run as correct user which may be root or splunk or other.

#  Unzip.sh
#  
#
#  
