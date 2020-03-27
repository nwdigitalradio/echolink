## SVXLink Installation

The installation process generally follows the R-Pi installation instructions on [Github here](https://github.com/sm0svx/svxlink/wiki/InstallSrcHwRpi)

#### Links to other notes
* [NOTES](NOTES.md)
* [RPi move notes](MOVE.md)

## Build Compass Image

__NOTE: Compass Image is deprecated, do not do this__

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

* Create the user account to support svxlink operation.
    * The svxlink user needs to have access to gpio and audio, and I also created mine so that it was not possible to log in (as a security item). You can still _su - svxlink_ once you have logged into the Pi if you need to do things as the svxlink user.

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
* Download and unpack the Sounds for the system to use from [this location](https://github.com/sm0svx/svxlink-sounds-en_US-heather/releases/tag/19.09/svxlink-sounds-en_US-heather-16k-19.09.tar.bz2)
* Unpack the sounds. **Note** that these must end up in the directory pointed to in the [ModuleEchoLink.conf file](https://github.com/nwdigitalradio/echolink/blob/master/ModuleEchoLink.conf).
    * Specifically line 28 DEFAULT_LANG=en_US.
    * This means the sounds must reside in the /usr/share/svxlink/sounds/en_US directory

```bash
cd /usr/share/svxlink/sounds/en_US
tar -xjvf svxlink-sounds-en_US-heather-16k-19.09.tar.bz2
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
This will build SvxLink and install it under _/usr/local_. The first cmake argument specifies the source directory so the build directory can be created anywhere. A common pattern is to place the build directly under the top source code directory, hence the ".." in the example above.

To use another install location (e.g. _/opt/svxlink_) use the following line when running cmake:
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

* **Note:** This was supposed to place the executables in the _/usr/lib/svxlink_ directory. Instead it placed the info in the _/usr/lib/arm-linux-gnueabihf/svxlink_ directory. This will need to get fixed in the future as svxlink looks for the module executables in the original location.
  * As a quick fix to test and also keep moving I did this part manually:

```bash
sudo mkdir /usr/lib/svxlink
cp -r /usr/lib/arm-linux-gnueabihf/svxlink/*.* /usr/lib/svxlink/)
```
### Modify the following configuration files from defaults to support the PI3/UDRC-II

* Configure [/etc/svxlink/svxlink.conf](https://github.com/nwdigitalradio/echolink/blob/master/svxlink.conf)
  * [Diff from original svxlink.conf file](https://github.com/nwdigitalradio/echolink/blob/master/svxlink.conf.diff)

* Configure [/etc/svxlink/svxlink.d/ModuleEchoLink.conf](https://github.com/nwdigitalradio/echolink/blob/master/ModuleEchoLink.conf)
  * [Diff from orginal ModuleEchoLink.conf file](https://github.com/nwdigitalradio/echolink/blob/master/ModuleEchoLink.conf.diff)

* Configure [/etc/svxlink/gpio.conf](https://github.com/nwdigitalradio/echolink/blob/master/gpio.conf)
  * [Diff from original gpio.conf file](https://github.com/nwdigitalradio/echolink/blob/master/gpio.conf.diff)

* With all configuration files set up as above we are now ready to
connect the radio and run the system.
  * **Note:** the password in _ModuleEchoLink.conf_ must match the
  EchoLink callsign used.

```bash
sudo svxlink_gpio_up
sudo svxlink

#   Or

su -
svxlink_gpio_up
svxlink
```

### Operation and Use

The last item, once this is running, is to adjust the output sound
levels using alsamixer. Typically the PCM will be set to -28 db or so
and the gain will be set at 0. When running alsamixer, select the UDRC
using _`<f-6>`_ and then select UDRC from the list. The actual settings
will depend on the radio.

Also, as configured, the system will allow a direct connection from
the local network. This works well as a test setup using one radio in
"reverse" mode and the svxlink radio in repeater mode. Once this
testing validates that communications are working both directions -
from the Echolink node to the radio and from an RF link to the radio
back into the Echolink node - then it is time to move to live testing
on the repeater.

The original configuration used RepeaterLogic as this is controlling a
repeater. According to Echolink protocol, when using repeaters the
callsign is CALL-R (i.e., AF4PM-R) and I assumed from all the
discussion that this also applied to the RepeaterLogic section. As it
turns out this is for direct repeater control and results in the
ability to send audio out over RF via the Echolink node and
svxlink-connected radio, but no audio gets back from in-coming RF
connections. This was pointed out by Ken Koster and is also can be
found in the svxlink wiki (though somewhat challenging to find). Once
the change was made to use SimplexLogic for a radio talking to a
repeater (vs direct repeater control) all worked well in both
directions.

The other item was that we needed to disable the "Roger Beep" as this
put the radio in an infinite beep loop. It is not clear exactly what
was happening but the beep was being repeated as with each beep it
issued another beep to "Roger" the previous beep. The only way to shut
it down was to turn off the radio or bring down svxlink with
_`<Cntl-C>`_.  Disabling the RogerSound stopped this problem from
occuring.

##### Startup, Status & Shutdown

On startup Echolink sometimes is unable to find an EchoLink station
directory using Internet services. Some systemd prerequisite is not
being met. If that happens stop then start svxlink. To facilitate
stopping/starting svxlink the local bin directory should contain these
scripts:

```
echolink-stop
echolink-start
echolink-status
```

## Echolink Presentations from SJCARS April meeting
