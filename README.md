## SVXLink Installation

The installation process generally follows the R-Pi installation instructions on [Github here](https://github.com/sm0svx/svxlink/wiki/InstallSrcHwRpi)

**Note:** Follow the Compass build instructions and not the basic build instructions provided at the above link. (i.e., Do not run rpi-update, it is not necessary for the Compass image and will remove the UDRC firmware support)

## Build Compass Image

###### [Install Compass Linux](https://nw-digital-radio.groups.io/g/compass/wiki/Installing-Compass-Linux-for-Raspberry-Pi)

### Basic Configuration

  * From a terminal command line, verify that the UDRC is recognized by typing the command

```bash
aplay -l
```
* (that's a lowercase l) and observe that udrc is listed as a card. If you do not see it listed, power down and remount the UDRC.
* To preset the pins and levels on the UDRC we provide a script. Execute the following:

```bash
cd ~
curl -L -s https://goo.gl/7rXUFJ > set-udrc-din6.sh
chmod +x set-udrc-din6.sh
sudo ~/set-udrc-din6.sh
```
* Optionally disable the internal sound chip by editing /boot/config.txt and commenting out this line
  * recommended unless you need it for something else:
```
#dtparam=audio=on
```
  * Ensure that everything is fully current and all versions aligned
```bash
sudo apt-get update
sudo apt-get upgrade
```
### Additional Configuration to consider for long-term R-Pi operation

**Note:** These changes were not implemented during the testing, but should be included or mitigated by using a larger SD-card or external Hard Disk/SSD to avoid premature storage failure)

  * Modify the /boot/config.txt file to allow increased usb current by adding or updating the following line
```bash
max_usb_current=1
```

  * Set up tmpfs partitions by editing /etc/fstab (edit is the command to invoke your favorite editor)
```bash
edit /etc/fstab
```
  * Modify the contents of /etc/fstab to include the following:
```bash
#temp filesystems for all the logging and stuff to keep it out of the SD card
tmpfs    /tmp    tmpfs    defaults,noatime,nosuid,size=100m    0 0
tmpfs    /var/tmp    tmpfs    defaults,noatime,nosuid,size=30m    0 0
tmpfs    /var/log    tmpfs    defaults,noatime,nosuid,mode=0755,size=100m    0 0
tmpfs    /var/spool/svxlink    tmpfs    defaults,noatime,nosuid,size=100m    0 0
```
  * Delete the files from the current mounted locations
```
rm files (/tmp , etc.)
```

  * Disable swap
```bash
sudo swapoff --all
sudo apt-get remove dphys-swapfile

reboot
```

## Build Svxlink from source on Github (Debian 8 - Jessie)
  * Create the user account to support svxlink operation.The svxlink user needs to have access to gpio and audio, and I also created mine so that it was not possible to log in (as a security item). You can still _su - svxlink_ once you have logged into the Pi if you need to do things as the svxlink user.
```bash
sudo useradd -c "Echolink user" -G gpio,audio -d /home/svxlink -m -s /sbin/nologin svxlink
```
  * Install the supporting libraries that are required for the installation.
```bash
sudo apt-get install make cmake
sudo apt-get install libsigc++-2.0-dev libgsm1-dev libpopt-dev tcl-dev libgcrypt20-dev libspeex-dev libasound2-dev libopus-dev alsa-utils alsa-tools doxygen groff
sudo apt-get install libqt4-dev rtl-sdr
```
  * Clone the Svxlink GitHub library for the latest version (This is required to provide full GPIO support)
```bash
git clone https://github.com/sm0svx/svxlink.git
```
  * Download and unpack the Sounds for the system to use from [this location](https://github.com/sm0svx/svxlink-sounds-en_US-heather/releases/download/14.08/svxlink-sounds-en_US-heather-16k-13.12.tar.bz2)
  * Unpack the sounds. Note that these must end up in the directory pointed to in the ModuleEchoLink.conf file. Specifically line 28 DEFAULT_LANG=en_US. This means the sounds must reside in the /usr/share/svxlink/sounds/en_US directory
```bash
tar -zxvf svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
```
### Build and install

Originally I had installed svxlink starting with a .tar file. While this worked it was a much earlier version of the code. While this generally worked, it did not have full configuration support for using GPIO control with the R-Pi. Increased fidelity of GPIO control proved to be critical to using the UDRC as the radio controller. Since a new version was released in February 2017 that included a GPIO configuration file, the older version was removed and the system rebuilt from the GitHub source master according to the following instructions.

##### General CMake Information for Svxlink

This version of SvxLink uses the CMake build system. The basic pattern for building Svxlink using CMake looks like this:
```bash
cd path/to/svxlink/src
mkdir build
cd build
cmake ..
make
make doc
make install
ldconfig
```
This will build SvxLink and install it under /usr/local. The first cmake argument specifies the source directory so the build directory can be created anywhere. A common pattern is to place the build directly under the top source code directory, hence the ".." in the example above.

To use another install location (e.g. /opt/svxlink) use the following line when running cmake:
```bash
cmake -DCMAKE_INSTALL_PREFIX=/opt/svxlink ..
```

* The "-D" switch is used to define CMake variables.
  * They are both standardized CMake variables and project specific ones.

To get install locations that would be used when building a binary package, use the following cmake line:

```bash
cmake -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR=/etc \
        -DLOCAL_STATE_DIR=/var ..
```
Cmake normally only needs to be run one time. After that the configuration is cached so only "make" need to be run. Make will rerun cmake when necessary (unless you add additional libraries that were not in the first run)

Some other good to know configuration variables that also can be set using -D command line switch are:
```
USE_ALSA          -- Set to NO to compile without Alsa sound support\\
USE_OSS           -- Set to NO to compile without OSS sound support\\
USE_QT            -- Set to NO to compile without Qt (no Qtel)\\
BUILD_STATIC_LIBS -- Set to YES to build static libraries as well as dynamic\\
LIB_SUFFIX        -- Set to 64 on 64 bit systems to install in the lib64 dir\\
```
### Svxlink Build as implemented

The build procedure used for the SJCARS svxlink installation using the R-Pi 3 and a UDRC-II is as follows:
```bash
cd svxlink-master
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var -DUSE_OSS=NO ..
make
make doc
sudo make install
ldconfig
```

* **Note:** This was supposed to place the executables in the /usr/lib/svxlink directory. Instead it placed the info in the /usr/lib/arm-linux-gnueabihf/svxlink directory. This will need to get fixed in the future as svxlink looks for the module executables in the original location.
  * As a quick fix to test and also keep moving I did this part manually:

```bash
sudo mkdir /usr/lib/svxlink
cp -r /usr/lib/arm-linux-gnueabihf/svxlink/*.* /usr/lib/svxlink/
```
### Modify the following configuration files from defaults to support the PI3/UDRC-II

  * Configure /etc/svxlink/svxlink.conf

```
###############################################################################
#                                                                             #
#                Configuration file for the SvxLink server                    #
#                                                                             #
###############################################################################

[GLOBAL]
MODULE_PATH=/usr/lib/svxlink
LOGICS=SimplexLogic
CFG_DIR=svxlink.d
TIMESTAMP_FORMAT="%c"
CARD_SAMPLE_RATE=48000
#LOCATION_INFO=LocationInfo
#LINKS=LinkToR4

[SimplexLogic]
TYPE=Simplex
RX=Rx1
TX=Tx1
MODULES=ModuleHelp,ModuleEchoLink
CALLSIGN=AF4PM-R
SHORT_IDENT_INTERVAL=60
LONG_IDENT_INTERVAL=0
IDENT_ONLY_AFTER_TX=4
#EXEC_CMD_ON_SQL_CLOSE=500
EVENT_HANDLER=/usr/share/svxlink/events.tcl
DEFAULT_LANG=en_US
RGR_SOUND_DELAY=-1
REPORT_CTCSS=131.8
TX_CTCSS=ALWAYS
MACROS=Macros
FX_GAIN_NORMAL=0
FX_GAIN_LOW=-12
#ACTIVATE_MODULE_ON_LONG_CMD=4:EchoLink
#QSO_RECORDER=8:QsoRecorder
#ONLINE_CMD=998877

[RepeaterLogic]
TYPE=Repeater
RX=Rx1
TX=Tx1
# MODULES=ModuleHelp,ModuleParrot,ModuleEchoLink
MODULES=ModuleEchoLink
CALLSIGN=AF4PM-R
SHORT_IDENT_INTERVAL=10
LONG_IDENT_INTERVAL=0
IDENT_ONLY_AFTER_TX=4
#EXEC_CMD_ON_SQL_CLOSE=500
EVENT_HANDLER=/usr/share/svxlink/events.tcl
DEFAULT_LANG=en_US
RGR_SOUND_DELAY=0
REPORT_CTCSS=131.8
TX_CTCSS=ALWAYS
MACROS=Macros
#SEL5_MACRO_RANGE=03400,03499
FX_GAIN_NORMAL=0
FX_GAIN_LOW=-12
#QSO_RECORDER=8:QsoRecorder
#NO_REPEAT=1
IDLE_TIMEOUT=5
#OPEN_ON_1750=1000
#OPEN_ON_CTCSS=131:2000
#OPEN_ON_DTMF=*
#OPEN_ON_SQL=5000
#OPEN_ON_SEL5=01234
#OPEN_SQL_FLANK=OPEN
#OPEN_ON_SQL_AFTER_RPT_CLOSE=10
IDLE_SOUND_INTERVAL=0
#SQL_FLAP_SUP_MIN_TIME=1000
#SQL_FLAP_SUP_MAX_COUNT=10
#ACTIVATE_MODULE_ON_LONG_CMD=4:EchoLink
#IDENT_NAG_TIMEOUT=15
#IDENT_NAG_MIN_TIME=2000
#ONLINE_CMD=998877

[LinkToR4]
CONNECT_LOGICS=RepeaterLogic:94:SK3AB,SimplexLogic:92:SK3CD
#DEFAULT_ACTIVE=1
TIMEOUT=300
#AUTOACTIVATE_ON_SQL=RepeaterLogic

[Macros]
1=EchoLink:9999#
9=Parrot:0123456789#
03400=EchoLink:9999#

[QsoRecorder]
REC_DIR=/var/spool/svxlink/qso_recorder
#MIN_TIME=1000
MAX_TIME=3600
SOFT_TIME=300
MAX_DIRSIZE=1024
#DEFAULT_ACTIVE=1
#TIMEOUT=300
#QSO_TIMEOUT=300
#ENCODER_CMD=/usr/bin/oggenc -Q \"%f\" && rm \"%f\"

[Voter]
TYPE=Voter
RECEIVERS=Rx1,Rx2,Rx3
VOTING_DELAY=200
BUFFER_LENGTH=0
#REVOTE_INTERVAL=1000
#HYSTERESIS=50
#SQL_CLOSE_REVOTE_DELAY=500
#RX_SWITCH_DELAY=500

[MultiTx]
TYPE=Multi
TRANSMITTERS=Tx1,Tx2,Tx3

[NetRx]
TYPE=Net
HOST=remote.rx.host
TCP_PORT=5210
AUTH_KEY="Change this key now!"
CODEC=S16
#SPEEX_ENC_FRAMES_PER_PACKET=4
#SPEEX_ENC_QUALITY=4
#SPEEX_ENC_BITRATE=15000
#SPEEX_ENC_COMPLEXITY=2
#SPEEX_ENC_VBR=0
#SPEEX_ENC_VBR_QUALITY=4
#SPEEX_ENC_ABR=15000
#SPEEX_DEC_ENHANCER=1
#OPUS_ENC_FRAME_SIZE=20
#OPUS_ENC_COMPLEXITY=10
#OPUS_ENC_BITRATE=20000
#OPUS_ENC_VBR=1

[NetTx]
TYPE=Net
HOST=remote.tx.host
TCP_PORT=5210
AUTH_KEY="Change this key now!"
CODEC=S16
#SPEEX_ENC_FRAMES_PER_PACKET=4
#SPEEX_ENC_QUALITY=4
#SPEEX_ENC_BITRATE=15000
#SPEEX_ENC_COMPLEXITY=2
#SPEEX_ENC_VBR=0
#SPEEX_ENC_VBR_QUALITY=4
#SPEEX_ENC_ABR=15000
#SPEEX_DEC_ENHANCER=1
#OPUS_ENC_FRAME_SIZE=20
#OPUS_ENC_COMPLEXITY=10
#OPUS_ENC_BITRATE=20000
#OPUS_ENC_VBR=1

[Rx1]
TYPE=Local
AUDIO_DEV=alsa:plughw:CARD=udrc,DEV=0
AUDIO_CHANNEL=1
SQL_DET=GPIO
#SQL_DET=VOX
SQL_START_DELAY=0
SQL_DELAY=0
SQL_HANGTIME=2000
#SQL_EXTENDED_HANGTIME=1000
#SQL_EXTENDED_HANGTIME_THRESH=15
#SQL_TIMEOUT=600
VOX_FILTER_DEPTH=20
VOX_THRESH=1000
CTCSS_MODE=2
CTCSS_FQ=131.8
#CTCSS_SNR_OFFSET=0
#CTCSS_OPEN_THRESH=15
#CTCSS_CLOSE_THRESH=9
#CTCSS_BPF_LOW=60
#CTCSS_BPF_HIGH=270
#SERIAL_PORT=/dev/ttyS0
#SERIAL_PIN=CTS:SET
#SERIAL_SET_PINS=DTR!RTS
#EVDEV_DEVNAME=/dev/input/by-id/usb-SYNIC_SYNIC_Wireless_Audio-event-if03
#EVDEV_OPEN=1,163,1
#EVDEV_CLOSE=1,163,0
GPIO_SQL_PIN=!gpio27
#SIGLEV_DET=TONE
SIGLEV_SLOPE=1
SIGLEV_OFFSET=0
#TONE_SIGLEV_MAP=100,84,60,50,37,32,28,23,19,8
SIGLEV_OPEN_THRESH=30
SIGLEV_CLOSE_THRESH=10
DEEMPHASIS=0
#SQL_TAIL_ELIM=300
#PREAMP=6
PEAK_METER=1
DTMF_DEC_TYPE=INTERNAL
DTMF_MUTING=1
DTMF_HANGTIME=50
#DTMF_SERIAL=/dev/ttyS0
#DTMF_MAX_FWD_TWIST=8
#DTMF_MAX_REV_TWIST=4
#1750_MUTING=1
#SEL5_DEC_TYPE=INTERNAL
#SEL5_TYPE=ZVEI1

[Tx1]
TYPE=Local
AUDIO_DEV=alsa:plughw:CARD=udrc,DEV=0
AUDIO_CHANNEL=1
PTT_TYPE=GPIO
# PTT_PORT=GPIO
PTT_PIN=gpio23
#SERIAL_SET_PINS=DTR!RTS
#PTT_HANGTIME=1000
TIMEOUT=300
TX_DELAY=200
CTCSS_FQ=131.8
#CTCSS_LEVEL=9
PREEMPHASIS=0
DTMF_TONE_LENGTH=100
DTMF_TONE_SPACING=50
DTMF_TONE_AMP=-18

[LocationInfo]
APRS_SERVER_LIST=noam.aprs2.net:14580
#STATUS_SERVER_LIST=aprs.echolink.org:5199
#LON_POSITION=12.10.00E
#LAT_POSITION=51.10.00N
#CALLSIGN=EL-DL0ABC
#FREQUENCY=438.875
#TX_POWER=8
#ANTENNA_GAIN=6
#ANTENNA_HEIGHT=20m
#ANTENNA_DIR=-1
PATH=WIDE1-1
BEACON_INTERVAL=60
#TONE=136
COMMENT=SvxLink by SM0SVX (svxlink.sourceforge.net)
</file>

  * Configure /etc/svxlink/svxlink.d/ModuleEchoLink
<file text ModuleEchoLink.conf>
[ModuleEchoLink]
NAME=EchoLink
ID=2
TIMEOUT=60
ALLOW_IP=172.16.1.0/24
#DROP_INCOMING=^()$
#REJECT_INCOMING=^()$
ACCEPT_INCOMING=^(AF4PM|N7NIX|K7UDR|KU7M|WA7FUS|N4RVE|K7NHE|KC7WJJ)$
#REJECT_OUTGOING=^()$
ACCEPT_OUTGOING=^(AF4PM|N7NIX|K7UDR|KU7M|WA7FUS|N4RVE|K7NHE|KC7WJJ)$
#CHECK_NR_CONNECTS=2,300,120
SERVERS=servers.echolink.org
CALLSIGN=AF4PM-R
PASSWORD=password
SYSOPNAME=Corky Searls
LOCATION=[Svx] 146.700, Lopez Island
#PROXY_SERVER=the.proxy.server
#PROXY_PORT=8100
#PROXY_PASSWORD=PUBLIC
MAX_QSOS=10
MAX_CONNECTIONS=11
LINK_IDLE_TIMEOUT=300
#AUTOCON_ECHOLINK_ID=9999
#AUTOCON_TIME=1200
#USE_GSM_ONLY=1
DEFAULT_LANG=en_US
DESCRIPTION="You have connected to a SvxLink node,\n"
	    "a voice services system for Linux with EchoLink\n"
	    "support.\n"
	    "Check out http://svxlink.sf.net/ for more info\n"
	    "\n"
	    "QTH:     Lopez Island\n"
	    "QRG:     Link on 146.700 MHz\n"
	    "CTCSS:   131.8 Hz\n"
	    "Trx:     My_transceiver_type\n"
	    "Antenna: My_antenna_brand/type/model\n"
```

* Configure /etc/svxlink/gpio.conf

```
###############################################################################
#
# Configuration file for the SvxLink server GPIO Pins
#
###############################################################################

# Space separated list of GPIO pins that point IN and have an
# Active HIGH state (3.3v = ON, 0v = OFF)
GPIO_IN_HIGH="gpio27"

# Space separated list of GPIO pins that point IN and have an
# Active LOW state (0v = ON, 3.3v = OFF)
GPIO_IN_LOW=""

# Space separated list of GPIO pins that point OUT and have an
# Active HIGH state (3.3v = ON, 0v = OFF)
GPIO_OUT_HIGH="gpio12 gpio23"

# Space separated list of GPIO pins that point OUT and have an
# Active LOW state (0v = ON, 3.3v = OFF)
GPIO_OUT_LOW=""

# User that should own the GPIO device files
GPIO_USER="svxlink"

# Group for the GPIO device files
GPIO_GROUP="svxlink"

# File access mode for the GPIO device files
GPIO_MODE="0664"
```

* With all configuration files set up as above we are now ready to connect the radio and run the system.
  * **Note:** the password in ModuleEchoLink.conf must match the EchoLink callsign used

```bash
sudo svxlink_gpio_up
sudo svxlink

#   Or

su -
svxlink_gpio_up
svxlink
```

### Operation and Use
The last item, once this is running, is to adjust the output sound levels using alsamixer. Typically the PCM will be set to -28 db or so and the gain will be set at 0. When running alsamixer, select the UDRC using <f-6> and then select UDRC from the list. The actual settings will depend on the radio.

Also, as configured, the system will allow a direct connection from the local network. This works well as a test setup using one radio in "reverse" mode and the svxlink radio in repeater mode. Once this testing validates that communications are working both directions - from the Echolink node to the radio and from an RF link to the radio back into the Echolink node - then it is time to move to live testing on the repeater.

The original configuration used RepeaterLogic as this is controlling a repeater. According to Echolink protocol, when using repeaters the callsign is CALL-R (i.e., AF4PM-R) and I assumed from all the discussion that this also applied to the RepeaterLogic section. As it turns out this is for direct repeater control and results in the ability to send audio out over RF via the Echolink node and svxlink-connected radio, but no audio gets back from in-coming RF connections. This was pointed out by Ken Koster and is also can be found in the svxlink wiki (though somewhat challenging to find). Once the change was made to use SimplexLogic for a radio talking to a repeater (vs direct repeater control) all worked well in both directions.

The other item was that we needed to disable the "Roger Beep" as this put the radio in an infinite beep loop. It is not clear exactly what was happening but the beep was being repeated as with each beep it issued another beep to "Roger" the previous beep. The only way to shut it down was to turn off the radio or bring down svxlink with <Cntl-C>. Disabling the RogerSound stopped this problem from occuring.

## Echolink Presentations from SJCARS April meeting
