DemTech-openwrt-setup 2015
===============================

TP-Link MR13U Version, 2015/04

## Introduction
This is a repository containing instructions on how to setup monitoring
tools for a [DemTech](http://demtech.dk) project.
The idea is to use devices with WiFi antennas to monitor queue lengths at polling places by registering how long WiFi devices are in range.
This readme describes how to setup the routers and start capturing and recording data.

Any questions or comments can be directed to DemTech at http://demtech.dk.

## Setup
The scripts are designed to be run on a Linux host machine via a shell, and onto a device running the [OpenWrt](https://openwrt.org/) Linux distribution for embedded devices (in this case devices with wireless antennas).
Instructions for rooting any router device should be present on the OpenWrt website.
Monitoring traffic generates a lot of data, so a usb storage is used to store the data.

Following a successful installation, a script will be started whenever the OpenWrt router (the client) boots.
This script logs all the wireless probe requests in the vicinity and once 1000kB data is collected, it is stores in the USB stick.

**IMPORTANT: Consult the legislation before recording people's MAC addresses. You have been warned.**

**Note:** Data will be captured on the channel the device is set to monitor by default.
One can argue whether or not this is desirable, but all devices should be caught scanning once in a while
(according to the 802.11 specification), since a scanning covers all available frequencies.

## Installation out of the box
Before installation we assume a [OpenWRT](https://openwrt.org/) image has been installed on the device.
An image for the TP-Link MR13U can also be found in the ``data`` folder.

If you have the same configuration as we have, it should be as simple as running ``init.sh`` in the root folder.
Before you run the script, please make sure the device is connect to the internet, which is necessary for ``opkg`` package installation.

## Manual installation
Failing automated install the router can be configured manually.
Please refer the ``scripts`` directory for inspiration.

Installation can be broken down to 3 steps:

1. [Setting up the white box](https://github.com/demtech/wb#white-box-setup)
2. [Installing monitoring tools](https://github.com/demtech/wb#installing-monitoring-tools)
3. [Starting up the tool]()

### White box setup
Please refer to [OpenWRT](https://openwrt.org/) for image installation.
The MR13U is connected to internet via ``wlan0`` interface.

### Host setup
This setup has been tested to work on a Arch Linux machine.
In the following scripts the host-machine is connected to the internet via the ``eth1`` interface, while being connected to the router via ethernet on the interface ``eth0``.
To enable connection between the white box and the host, one should setup an ip for the host-machine.

````bash
sudo ip addr add 192.168.1.2/24 broadcast 192.168.1.255 dev eth0
````
A device with a clean OpenWrt installation should resolve itself to 192.168.1.1, which should probably be changed if you are setting up multiple devices.

#### Device configuration
To be able to connect to the device via the shell and Ethernet you need to configure the OpenWrt configuration.
This can be automated, but it is simpler to just log in to the web-interface, by pointing a browser to 192.168.1.1.
When logging in as 'root' the first time, no password should be needed.

First you should set the password of the device, so it can be
accessed via ssh. This can be done in the system-tab -> administration.

If you have multiple devices you would probably want to give
the ethernet interface another address (in the Network tab).

Lastly it is a good idea to synchronize the time (in the System-tab).
Note that when you change the interface above, the device may no longer be available via 192.168.1.1.

### Installing monitoring tools
After configuring the device the next step is to install the monitoring scripts on the device.

#### Monitoring
For monitoring we are using ``tcpdump`` which is a part of opkg - the OpenWRT package manager.
However, there is not enough memory in the MR13U router, so we are forced to install it on the USB stick.

At boot we will also have to start the actual monitoring by calling ``tcpdump``.
This call is performed in [``capture.sh``](https://github.com/demtech/wb/blob/master/scripts/capture.sh) where we essentially create a unique number (to differentiate between monitoring across boots) and starts ''tcpdump''.

#### Startup-scripts
To start these monitoring processes a script called [``startup.sh``](https://github.com/demtech/wb/blob/master/scripts/startup.sh) has been written.
It installs the ``tcpdump`` package, creates a temporary folder for the data
and starts the ``capture.sh`` script.

#### Summary: How to install monitoring tools
So; for the monitoring-part to work the ``init.sh`` and ``capture.sh`` scripts both needs to be transferred to the white box.
And for the ``capture.sh`` script to be executed on boot, a line
will need to be inserted into ``/etc/crontab/root`` (which is a simple .sh file run on boot).
See [``setup_monitoring.sh#22``](https://github.com/demtech/wb/blob/master/scripts/setup_monitoring.sh#L22) for inspiration.

## Technical difficulties
In the early trails, we have been struggling with drivers randomly crashing irregularly.
In particular this appeared to be a problem when using the FAT file-system on the USB devices
to store the data.
The problem have been fixed in more recent versions of OpenWRT, which is why we are using the (at the time
unfinished) Barrier Breaking version via ext4 file-system.

## Conclusion
This is an exceptionally powerful tool since even the smallest and simplest devices with wifi-antennas are capable of surveilling a large number of people over a large amount of time.
The information captured by tcpdump can be used for many purposes, ranging from tracking individuals to perhaps even triangulate positions if more routers are set up.

The setup are not perfect, however.
There are still a number of technical hurdles to climb, so it is still not open for layman.
Another large challenge is the planned iOS change where MAC-addresses are randomly shifted when performing probe requests.
This will make us unable to track any user for a longer period of time, resulting in a serious blow to this type of tools
([see TechCrunch](http://techcrunch.com/2013/06/14/ios-7-eliminates-mac-address-as-tracking-option-signaling-final-push-towards-apples-own-ad-identifier-technology/?_ga=1.61162732.1122695649.1406633760)).

Please direct any questions or comments to the DemTech research group at http://demtech.dk
