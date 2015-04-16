#!/bin/ash
##
## A script to start the monitoring tool
##
## Author: jensep@gmail.com
## Author: jian@demtech.dk

sleep 2 ;

# Check if tcpdump already started
pgrep tcpdump && exit 0

# Check if mounted correctly, if not do it before anything else happened
while [ -f /opt/USB_DISK_NOT_PRESENT ]
do
    sleep 3

    mount="/dev/sda1"

    if grep -qs "$mount" /proc/mounts; then
        echo "It's mounted."
    else
        echo "It's not mounted."
        mount "$mount" /mnt/usb
        if [ $? -eq 0 ]; then
            echo "Mount success!"
        else
            echo "Something went wrong with the mount..."
        fi
    fi
done

# Check if data folder exists, if not creat one
if [ ! -d /opt/data ] ; then
    mkdir -p /opt/data
fi

# Create a counter to keep track of (possible) different
# running instances across boots
if [ ! -f /opt/n ] ; then
    echo "0" > /opt/n
fi

# Increment the counter
N=$(($(cat /opt/n) + 1))
echo $N > /opt/n

# Start tcpdump with flags:
# -i      The interface
# -B      Buffer size of the OS to limit consumption
# -w      Binary output file
# -C      Capture size before file-rotation (in kB)
# -n      Don't resolve addresses
# -e      Include link-level headers
# -q      Quiet means reduced output (not really sure what it does)
# -s      Package size (we don't care about the actual data)

/opt/usr/sbin/tcpdump -i wlan0 -B 1024 -w "/opt/data/${N}_dump" -C 1 -neq -s 0 &

