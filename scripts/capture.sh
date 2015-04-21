#!/bin/ash
##
## A script to start the monitoring tool
##
## Author: jensep@gmail.com
## Author: jian@demtech.dk

sleep 1

# Check if tcpdump already started
pgrep tcpdump && exit 0

sleep 1

# Put wireless device in monitor mode and enable wireless device, in case needed
ifconfig wlan0 down
sleep 1
iw dev wlan0 set type monitor
sleep 1
ifconfig wlan0 up

# Check if mounted correctly, if not do it before anything else happened
if [ -f /mnt/sda2/USB_DISK_NOT_PRESENT ] ; then
    sleep 1

    mount="/dev/mapper/usb_luks"

    if grep -qs "$mount" /proc/mounts; then
        echo "Sda2 is mounted."
    else
        echo "Sda2 is not mounted."

        mount "$mount" /mnt/sda2
        if [ $? -eq 0 ]; then
            echo "Mount success!"
        else
            echo "Something went wrong with the mount..."
        fi
    fi
fi

# Only try to mount once
if [ -f /mnt/sda2/USB_DISK_NOT_PRESENT ] ; then
    exit 0
fi

# Check if data folder exists, if not creat one
if [ ! -d /mnt/sda2/data ] ; then
    mkdir -p /mnt/sda2/data
fi

# Create a counter to keep track of (possible) different
# running instances across boots
if [ ! -f /mnt/sda2/n ] ; then
    echo "0" > /mnt/sda2/n
fi

# Increment the counter
N=$(($(cat /mnt/sda2/n) + 1))
echo $N > /mnt/sda2/n

# Track restart time
echo $N >> /mnt/sda2/t
echo $(date) >> /mnt/sda2/t

# Start tcpdump with flags:
# -i      The interface
# -B      Buffer size of the OS to limit consumption
# -w      Binary output file
# -C      Capture size before file-rotation (in kB)
# -n      Don't resolve addresses
# -e      Include link-level headers
# -q      Quiet means reduced output (not really sure what it does)
# -s      Package size (we don't care about the actual data)

/usr/sbin/tcpdump -i wlan0 -B 1024 -w "/mnt/sda2/data/${N}_dump" -C 1 -neq -s 0 &

