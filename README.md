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
present on the OpenWrt website. Monitoring traffic
generates a lot of data, so for this setup we are using a 3GPP device
to transfer the data to a server for storage.

Following a successful installation, a script will be started whenever
the OpenWrt router (the client) boots. This script logs all the
wireless probe requests in the vicinity and once 100kB data is collected,
it sends it to the given host.

**IMPORTANT: Consult the legislation before recording people's MAC
addresses. You have been warned.**

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
	
	sudo ./setup.sh 192.168.0.1 1.2.3.4 1234 eth0 wlan0
	
**HOWEVER**: Before the 3G modem can be used, it needs to be
activated. This can be done from any computer. See the section
on [Activation of the 3G modem](https://github.com/demtech/wb/blob/master/README.md#activation-of-the-3g-modem).
	
## Manual installation

Failing automated install the router can be configured manually.
Please refer to ''setup.sh'' and the ''scripts'' directory
for inspiration.

Installation can be broken down to 3 steps:

1. [Setting up the device](https://github.com/demtech/wb#device-setup)
2. [Installing monitoring tools](https://github.com/demtech/wb#installing-monitoring-tools)
3. [Configuring 3G modem](https://github.com/demtech/wb#configuring-3g-modem)

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

### Installing monitoring tools

After configuring the device the next step is
to install the monitoring scripts on the device.

#### Monitoring
For monitoring we are using ``tcpdump`` which is a part of opkg -
the OpenWRT package manager. However, there is not enough memory
in the MR3020 router, so we are forced to install it on volatile
memory after every boot.

At boot we will also have to start the actual monitoring by
calling ``tcpdump``. This call is performed in [``capture.sh``](https://github.com/demtech/wb/blob/master/scripts/capture.sh)
where we essentially create a unique number (to differentiate between
monitoring across boots) and starts ''tcpdump''.

#### Post-processing
This data needs to be
forwarded to a server, so whenever 100kB of data has been recorded,
it is processed by [``postproccess.sh``](https://github.com/demtech/wb/blob/master/scripts/postprocess.sh).
This script does four things: It 1) creates a unique id for the router
(based on the ip) so we can distiguish the data on the server, 2) converts
the binary ``tcpdump``-data to a textual representation, 3) sends it
over SSH to the server and 4) deletes the data from the white box.
The third step requires a key. For now it's
positioned in ``/root/sshkey``. This is very unsafe and should be changed!
:-) However, changing the data-transfering and processing should be
confined to manipulating the``postproccess.sh`` script (except for any
key-exchanging, which should probably be made in the ``startup.sh`` script
seen below).

#### Startup-scripts
To start these processes a script
called [``startup.sh``](https://github.com/demtech/wb/blob/master/scripts/startup.sh)
has been written. The first part relates to the 3G modem, so I'll skip to #31 for
now. It installs the ``tcpdump`` package, creates a temporary folder for the data
and starts the ``capture.sh`` script.

#### Summary: How to install monitoring tools
So; for the monitoring-part to work the ``startup.sh``, ``capture.sh``
and ``postprossess.sh`` scripts all  needs to be transfered to the white
box. And for the ``startup.sh`` script to be executed on boot, a line
will need to be inserted into ``/etc/rc.local`` (which is a simple .sh
file run on boot). See [``setup_monitoring.sh#22``](https://github.com/demtech/wb/blob/master/scripts/setup_monitoring.sh#L22) for inspiration.

### Configuring 3G modem
I hope my step-by-step guides are not tiring you, because here comes
yet another one. Four things is needed for the modem to work:

1. Interface and PPP setup
2. Driver configuration on the white box
3. Activation of the 3G modem
4. Boot-configuration of the 3G modem

Note from Jens: This took me a staggering amount of time to get
right. If you run into trouble and think I can alleviate some of
your pain to a fraction of the level I was exposed to, this might
be a good time to consider writing me.

#### Interface and PPP setup
This - and all others related to the dongle - is described in the [``setup_dongle.sh``](https://github.com/demtech/wb/blob/master/scripts/setup_dongle.sh)
script.

Before setting up the modem we should configure the interface, so
the router can attach the device as soon as it finds it. It's as
simple as adding lines to the ``/etc/config/network`` file (see
[``setup_dongle.sh#37-49``](https://github.com/demtech/wb/blob/master/scripts/setup_dongle.sh#L37).
Note that the PIN-code is needed in the option ``pincode``.

Setting up the Point-to-Point Protocol is vendor-specific, so if
something else than Fullrate is used, it should probably be changed.
For Fullrate the only change in the chat-script is to alter the
string ``ATD*99***1#`` to ``"ATD*99#``.

See [https://dev.openwrt.org/browser/trunk/package/comgt/files/3g.chat?rev=5433](https://dev.openwrt.org/browser/trunk/package/comgt/files/3g.chat?rev=5433) for the original 3g.chat file.

#### Drivers
First the necessary packages are installed. Then (and this is
where the fun begins) we need to 'flip' the device from a flash-storage
to an actual 3G modem. Normally vendors places two devices in one USB
stick: one with the drivers and one with the actual functionality. So
when Windows or Mac reads the driver from the flash-drive, the driver
automatically flips state. To do that on the white boxes, we need to
send the USB stick a message. The message only fits for for E353 device,
so if you get another stick you will need to find a different message.

The messages comes with the ``usb-modeswitch`` package, and can be
found in ``/etc/usb-mode.json``. The data might change, so the code
in the [``setup_dongle.sh#38-40``](https://github.com/demtech/wb/blob/master/scripts/setup_dongle.sh#L38)
might deprecate. In that case I have stored a functional file in the data folder:
[``usb-mode.json``](https://github.com/demtech/wb/blob/master/data/usb-mode.json).

The last step in the driver configuration is to load the actual
drivers by the ``insmod`` command [``setup_dongle.sh#60-62``](https://github.com/demtech/wb/blob/master/scripts/setup_dongle.sh#L60).
For debugging purposes it might be worth noting the device id before and
after the switch. The vendor (12d1) stays the same, but the product
switches from 1f01 to 1001. 

#### Activation of the 3G modem
Now the router should be able to see the modem (after a reboot).
Before it can be used it should be activated. This is another omnious
process involving a python script that took me quite some time to
procure: [``unlock.py``](https://github.com/demtech/wb/blob/master/scripts/unlock.py).

It takes an IMEI number as input, and gives the key needed to unlock
the device as an output.

To obtain the IMEI number open a connection to the router by cat'ing
the device (typically ``/dev/ttyUSB0``) in the background.
If you echo the string ``ATI\r`` (with special characters) to the modem
an IMEI should pop up in the console. Give that to the script and
Send the result to the device formatted like so: ``AT^CARDLOCK="{CODE}"\r``
where ``{CODE}`` is the resulting unlock-code. Now your device should be
unlocked.

#### Boot-configuration of the 3G modem
This section related to the first 31 lines in
[``startup.sh``](https://github.com/demtech/wb/blob/master/scripts/startup.sh),
which I assume have already been transferred to the device.

At startup the drivers will need to be loaded and if the device
is not available then (lines 19-23), a failure occurred at setup.

After this the ppp0 interface should connect and the modem can
go online. This is an asynchronous process, so the script sleeps
for 30 seconds, before trying to reach the package server and
install the monitoring tools.

## Conclusion
This is an exceptionally powerful tool since even the smallest
and simplest devices with wifi-antennas are capable of
surveilling a large number of people over a large amount of time.
The information captured by tcpdump can be used for many
purposes, ranging from tracking individuals to perhaps even
triangulate positions if more routers are set up. 

The setup are not perfect, however. There are still a number
of technical hurdles to climb, so it is still not open for
layman. Another large challenge are the planned iOS changes
where MAC-addresses are randomly shifted. This will make us
unable to track any user for a longer period of time, 
resulting in a serious blow to this type of tools
([see TechCrunch](http://techcrunch.com/2013/06/14/ios-7-eliminates-mac-address-as-tracking-option-signaling-final-push-towards-apples-own-ad-identifier-technology/?_ga=1.61162732.1122695649.1406633760)).

Lastly, I will mention that I have been struggling with drivers
randomly crashing irregularly. In particular this appeared to 
be a problem when using the FAT filesystem on the USB devices
to store the data. The problem have been fixed in more recent
versios of OpenWRT, which is why we are using the (at the time
unfinished) Barrier Breaking version.

Please direct any questions or comments to the DemTech research group
at http://demtech.dk
