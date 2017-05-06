# echolink
Files used to enable Echolink on the SJCARS 2M repeater using a Raspberry Pi & UDRC.

## Attribution

* Corky Searls AF4PM
  * with help from Ken Koster N7IPB & Basil Gunn N7NIX

## Files

These config files are found in /etc/svxlink

* svxlink.conf
* gpio.conf

This config file is found in /etc/svxlink/svxlink.d

* ModuleEchoLink.conf

## Configuration Notes

* Configuration files live here: /etc/svxlink/
* I found the [svxlink wiki InstallSrcHwRpi](https://github.com/sm0svx/svxlink/wiki/InstallSrcHwRpi) entries helpful.
  * Scroll down to __Problems (and fixes) along the way__ section
* The last variable changed to enable working on repeater was RGR_SOUND_DELAY=-1 in the [SimplexLogic] section of svxlink.conf
  * RGR_SOUND_DELAY=50 -> -1

## To use systemd start up files
* After cloning repository
```
git clone https://github.com/nwdigitalradio/echolink.git
```

* As root:
  * Copy systemd files to /etc/systemd/system

```
sudo su
cp ~/echolink/systemd/* /etc/systemd/system/
```

* As root:
  * Enable systemd files

```
systemctl enable svxlink_gpio_setup.service
systemctl enable svxlink.service
```
## To Check Status, Start & Stop echolink
* There are 3 files in ~/echolink/systemd/bin
  * echolink-start
  * echolink-stop
  * echolink-status
* You don't need to be root to run echolink-status but **DO** need to be root to run echolink-start & echolink-stop.
* Once the 2 systemctl enable commands are run (see above), echolink will start automatically from boot.

## Logfile

* To watch the log file
```
tail -f /var/log/svxlink.log
```

* To check all stations that tried to login
```
grep -i "station " /varlog/svxlink.log
```
* To check number of times Echolink IDed.
```
grep -i "sending" /var/log/svxlink.log
```
### log file rotate
* Added this file /etc/rsyslog.d/01-svxlink.conf
```
if $programname == 'svxlink' then /var/log/svxlink.log
if $programname == 'svxlink' then ~
```

* Added this file /etc/logrotate.d/svxlink
```
/var/log/svxlink.log {
	rotate 7
	daily
	missingok
	notifempty
	delaycompress
	compress
	postrotate
		invoke-rc.d rsyslog rotate > /dev/null
	endscript
}
```

#### Tested log file rotate
```
service rsyslog restart
echo "test log rotate for svxlink, view status before ..."

grep svxlink /var/lib/logrotate/status
logrotate -v -f /etc/logrotate.d/svxlink

echo "test log rotate, view status after ..."
grep svxlink /var/lib/logrotate/status
```
## Notes from Ken Koster N7IPB

### Modify your svxlink.conf: (this was the main issue)
1. Change Logics=RepeaterLogic to Logics=SimplexLogic
RepeaterLogic is for systems where svxlink controls the repeater and is
connected to the repeater RX/TX directly.

2. SQL_DET
If you're running the radio on the frequency used by a repeater you can't use
VOX unless the radio is running squelched.

If you run gpio then you have to make sure the CSQ signal isn't present during
the repeater hang-time (or the hang-time is really short).   This means you
need to condition it with CTCSS and it also means the repeater has to transmit
CTCSS on it's output only when a carrier is on it's input.  You want it to
drop CTCSS during the hangtime.

It the repeater is configured that way,  then you can just put the Echolink
radio in CTCSS mode.  An alternative would be to use CTCSS decode mode in
svxlink and let it handle the CTCSS, this requires using the 9600b output of
the radio.

I suspect you know the above,  but I'm being thorough.  My radio's are set for
open squelched flat audio so I have to configure them for CTCSS or use the
SIGLEV detector which requires calibrating the radios.

There are two other parameters you will probably want to play with.

In [RX1] you might want to set a value for SQL_DELAY if you notice a double
blip when the Echolink TX is unkeyed.

In [TX1] you will want to play with the TX_DELAY to match the radio.   I
notice you have it at 500 and that guarantees that the radio is up and
transmitting when the announcements occur but you may find it adds a bit to
much delay in the audio.
