#!/bin/ash
##
## A script to stop the monitoring tool
##
## Author: jian@demtech.dk


# kill tcpdump
kill -9 $(pgrep tcpdump)

# umount tcpdump
umount /mnt/sda2 && cryptsetup luksClose usb_luks




