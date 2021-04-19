#!/bin/sh
/Library/NessusAgent/run/sbin/nessuscli agent unlink
/Library/NessusAgent/run/sbin/nessuscli agent link --key=e296eca2853e47c917d4eb5eb2864107751d4d391c2b7e04b1bac758235c0d54 --groups=OSX --cloud --proxy-host=127.0.0.1 --proxy-port=22018
