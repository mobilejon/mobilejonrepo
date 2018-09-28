#!/bin/sh
/usr/sbin/lpadmin -x Printer01
/usr/sbin/lpadmin -p Printer01 -E -v lpd://1.1.1.1 -o printer-is-shared=false -P /Library/Printers/PPDs/Contents/Resources/en.lproj/Xerox\ EX\ C60-C70\ Printer


#  CreativePrinters.sh
#  
#
#  Created by Jon Towles on 7/31/18.
#  
