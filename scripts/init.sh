Install to USB

Edit /etc/profile and add the new mount point to your paths variables:

export PATH=<current default path>:/opt/bin:/opt/sbin:/opt/usr/bin:/opt/usr/sbin
export LD_LIBRARY_PATH=<current default LD library path>:/opt/lib:/opt/usr/lib

opkg -dest usb install tcpdump

mkdir -p /mnt/usb
ln -s /mnt/usb /opt

touch /mnt/usb/USB_DISK_NOT_PRESENT



*/1 * * * * . /etc/profile; /root/capture.sh
