
# Enable/disable wlan0 on WB
ifconfig wlan0 up/down

# Connect to wifi
ifconfig wlan0 up;
iw dev wlan0 connect Demtech;
udhcpc -i wlan0;
echo "nameserver 8.8.8.8" >> /etc/resolv.conf;

# Install USB support package
opkg update;
opkg install kmod-usb-storage;
opkg install kmod-fs-ext4;
opkg install block-mount;
mkdir -p /mnt/sda1;
touch /mnt/sda1/USB_DISK_NOT_PRESENT

mount /dev/sda1 /mnt/sda1

# -----------------------------------------------------------------------------
# Option 1. Use dest

ln -s /mnt/sda1 /opt


# Install to USB

# Edit /etc/profile and add the new mount point to your paths variables:
export PATH=<current default path>:/opt/bin:/opt/sbin:/opt/usr/bin:/opt/usr/sbin
export LD_LIBRARY_PATH=/opt/lib:/opt/usr/lib

# Edit /etc/opkg.conf
dest usb /opt

# Install to USB

opkg -dest usb install tcpdump



# -----------------------------------------------------------------------------
# Option 2. Use exroot
mkdir -p /mnt/sda1;
touch /mnt/sda1/USB_DISK_NOT_PRESENT;
mount /dev/sda1 /mnt/sda1;

# extroot to extend root space
tar -C /overlay -cvf - . | tar -C /mnt/sda1 -xf -

# /etc/config/fstab
config mount
        option target '/overlay'
        option uuid '1902a323-79a6-4b1a-a511-a58655974ee9' # run block detect
        option enabled '1'
        option fstype 'ext4'

# Install package
opkg update;
opkg install tcpdump;

opkg install cryptsetup lvm2 kmod-crypto-aes kmod-crypto-misc kmod-crypto-xts kmod-crypto-iv kmod-crypto-cbc kmod-crypto-hash kmod-dm
echo sha256_generic >/etc/modules.d/11-crypto-misc



# -----------------------------------------------------------------------------
# Descrpt & mount encrypted partition
# mount -t jffs2 /dev/mtdblock3 /mnt/mtb3/
# cat /mnt/mtb3/mnt/pass  | cryptsetup luksOpen /dev/sda2 usb_luks

cryptsetup luksOpen /dev/sda2 usb_luks;
mount /dev/mapper/usb_luks /mnt/sda2
umount /mnt/sda2 && cryptsetup luksClose usb_luks



# -----------------------------------------------------------------------------
# Step 2. Enable wlan0 and start tcpdump

ifconfig wlan0 down

# cronjob for restarting tcpdump
#       M   H D M W
# echo "*/5 * * * * . /etc/profile; /root/capture.sh" >> /etc/crontabs/root
echo "*/5 * * * * /root/capture.sh" >> /etc/crontabs/root


1 7 27 *  * ifconfig wlan0 up
*/5 7-20 27 * * /root/capture.sh
1 20 27 * * /root/stop.sh

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# HOST Init cryptsetup

sudo cryptsetup -v --cipher aes-xts-plain64 --key-size 256 --hash sha1 --iter-time 1000 --use-urandom --verify-passphrase luksFormat /dev/sdc2
sudo cryptsetup open --type luks /dev/sdc2 wb;
sudo mkfs -t ext4 /dev/mapper/wb

mount /dev/mapper/wb /mnt
umount /mnt
cryptsetup close wb

sudo ip addr add 192.168.1.101/24 broadcast 192.168.1.255 dev eth0
