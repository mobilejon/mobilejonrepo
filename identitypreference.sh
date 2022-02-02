#!/bin/sh
# Variables
loggedInUser="$(defaults read '/Library/Application Support/AirWatch/Data/CustomAttributes/CustomAttributes' 'EnrollmentUser')"
## Script
security set-identity-preference -c $loggedInUser -s *.vmwareidentity.com

#  IdentityPreference.sh
