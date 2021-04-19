#!/usr/bin/python

from LaunchServices import *

LSSetDefaultHandlerForURLScheme("mailto", "com.microsoft.outlook")
LSSetDefaultRoleHandlerForContentType("com.apple.ical.ics", kLSRolesAll, "com.microsoft.outlook")
LSSetDefaultRoleHandlerForContentType("public.vcard", kLSRolesAll, "com.microsoft.outlook")
LSSetDefaultRoleHandlerForContentType("com.apple.mail.email", kLSRolesAll, "com.microsoft.outlook")

#  OutlookDefault.py
#  
#
#  Created by c52722 on 4/13/21.
#  
