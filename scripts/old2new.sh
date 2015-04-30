src/gz chaos_calmer_base http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/base
src/gz chaos_calmer_telephony http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/telephony
src/gz chaos_calmer_packages http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/packages
src/gz chaos_calmer_routing http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/routing
src/gz chaos_calmer_luci http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/luci
src/gz chaos_calmer_management http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/management

    mount_root;
    mtd -r erase rootfs_data;
    reboot -f

    ifconfig wlan0 up;
    iw dev wlan0 connect AndroidAPdp;
    udhcpc -i wlan0;
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf

    opkg update;
    opkg install luci

    /etc/init.d/uhttpd start


Checksum: 52463306efa64407f9a0de68adcfe6a1
