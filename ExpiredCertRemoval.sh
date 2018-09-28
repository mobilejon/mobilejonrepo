#!/bin/sh
# Grabs the expired certificate hashes
expired=$(security find-identity | grep EXPIRED | awk '{print $2}')

# Check for certs

if [ -z "$expired" ]
then
echo "No expired certificates, we're all good"
else
# Deletes the expired certs via their hash
echo "Deleting expired certs"
security delete-certificate -Z $expired /Library/Keychains/System.keychain
fi
#  ExpiredCertRemoval.sh
#  
#
#  Created by Jon Towles on 7/30/18.
#  



