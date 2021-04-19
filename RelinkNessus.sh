#!/bin/sh
/Library/NessusAgent/run/sbin/nessuscli agent unlink
/Library/NessusAgent/run/sbin/nessuscli agent link --key=KEY --groups=OSX --cloud --proxy-host=127.0.0.1 --proxy-port=22018
