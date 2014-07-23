DemTech-openwrt-setup
=====================

Version 0.2

## Introduction

This is a repository containing instructions on how to setup monitoring
tools for a [DemTech](http://demtech.dk) project.
The idea is to use devices with WiFi antennas to monitor
queue lengths at polling places by registering how long
WiFi devices are in range. This readme describes how to
setup the routers and start capturing and recording data.

Any questions or comments can be directed to DemTech at http://demtech.dk.

## Setup
The scripts are designed to be run on a Linux host machine
via a shell, and onto a device running the
[OpenWrt](https://openwrt.org/) Linux distribution for embedded
devices (in this case devices with wireless antennas).
Instructions for rooting any router device should be
present on the OpenWrt website<sup>[1]</sup>. Monitoring traffic
generates a lot of data, so for this setup we are using a 3GPP device
to transfer the data to a server for storage.

Following a successful installation, a script will be started whenever
the OpenWrt router (the client) boots. This script logs all the
wireless probe requests in the vicinity and once 100kB data is collected,
it sends it to the given host.

The following readme is split into two: Installation
(prior to gathering data at polling places) and setup
(at the polling places). To empower as many users as possible it is
very detailed, down to every necessary command.

**IMPORTANT: Consult your contries legislation before starting
to record people's MAC addresses! You have been warned.**

**Note:** Data will be captured on the channel the device is set
to monitor by default. One can argue whether or not this is desirable,
but all devices should be caught scanning once in a while
(according to the 802.11 specification), since a scanning covers
all available frequencies.

## Installation out of the box

Before installation we assume a OpenWRT image has been installed
on the device. An image for the TP-Link MR3020 can be found in the
''data'' folder.

If you have the same configuration as we have, it should be as 
simple as running ''setup.sh'' in the root folder with up to five
parameters: The new address of the router, the address of the
server to store the data, the PIN code for the 3G device, the name of
the network interface where the router is connected and lastly the
name of the network interface where the host-machine is connected to
the internet. As an example this should work:

	````bash
	sudo ./setup.sh 192.168.0.1 1.2.3.4 1234 eth0 wlan0
	````
## Manual installation

Failing automated install the router can be configured manually.
Please refer to ''setup.sh'' and the ''scripts'' directory
for inspiration.

Installation can be broken down to 3 steps:

1. Setting up the device
2. Installing monitoring tools
3. Setting up data-transering device

### Device setup
This setup has been tested to work on a Debian 7 machine. In
the following scripts the host-machine is connected to the internet
via the ''wlan0'' interface while being connected to the router via
ethernet on the interface ''eth0''.

#### Routing
To enable connection between the devices and the host, and
between the devices and the internet (we need this to install
packages on the device), one should setup a route table on the
host-machine to allow routes to go through the host. In this
setup the host-machine is set to respond on 192.168.1.2.

1. First establish the host address alias
	````bash
	sudo ip addr add 192.168.1.2/24 dev eth0
	````

2. Then configure NAT, so the devices can resolve addresses.

	````bash
	sudo iptables -A FORWARD -o wlan0 -i eth0 -s 192.168.1.0/24 -m conntrack --ctstate NEW -j ACCEPT
	sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	sudo iptables -t nat -F POSTROUTING
	sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
	````

3. Lastly the line `#net.ipv4.ip_forward=1` should be uncommented
	in the file `/etc/sysctl.conf`.

	If the settings are not stored, this needs to be run after
	each boot. A great article on the ubuntu help center describes the
	above steps in more detail and some information on how to persist
	the changes:
	https://help.ubuntu.com/community/Internet/ConnectionSharing.

	A device with a clean OpenWrt installation should resolve
	itself to 192.168.1.1, which should probably be changed if
	you are setting up multiple devices.

#### Device configuration
To be able to connect to the device via the shell and ethernet
you need to configure the OpenWrt configuration. This can be
automated, but it is simpler to just log in to the web-interface,
by pointing a browser to 192.168.1.1. When logging in as 'root' the first
time, no password should be needed.

First you should set the password of the device, so it can be
accessed via ssh. This can be done in the system-tab -> administration.

If you have multiple devices you would probably want to give
the ethernet interface another address (in the Network tab).
As you can see below I have chosen 192.168.1.101 as an example
here. But anything goes.

Lastly it is a good idea to synchronize the time (in
the System-tab). Note that when you change the interface above,
the device is no longer available via 192.168.1.1.

### Monitoring tools

After configuring the device the next thing you need to do, is
to install the monitoring scripts on the device.

... TBC

## Polling-place setup
When the routers have been configured they are ready to capture data.
However, before being functional at the polling stations, two
things need to happen: First the clients (OpenWrt devices)
should be positioned in the vicinity of the polling queue and second
the keys for the server and the hashing of the MAC addresses should
be distributed.

### Positioning of the devices

... TBC

### Key distribution
... To be continued

## Conclusion
This is an exceptionally powerful tool since even the smallest
and simplest devices with wifi-antennas are capable of
surveilling a large number of people over a large amount of time.
The information captures by tcpdump can be used for many many
purposes, ranging from tracking individuals to perhaps even
triangulate positions if more routers are set up. 

The setup are not perfect, however. Tcpdump only captures traffic
on the default channel of the antenna, which limits a lot of the
logged data to scans from mobile devices searching for networks. 

Also, I have been struggling with drivers randomly crashing
irregularly. In particular this appeared to be a problem when using
the FAT filesystem on the USB devices to store the data. The problem
have been fixed in more recent versios of OpenWRT, which is why we
are using the (unfinished) Barrier Breaking version.

As a partial fix, I have included a cron-job in the setup-scripts
that checks if any data have been logged for a minute. If not, we
restart the wireless interface.

Please direct any questions or comments to the DemTech research group
at http://demtech.dk

[1]: https://openwrt.org/ "OpenWrt homepage"
