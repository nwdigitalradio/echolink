# echolink
Files used to enable Echolink on the SJCARS 2M repeater using a Raspberry Pi & UDRC.

## Attribution

* Corky Searls AF4PM
  * with help from Ken Koster N7IPB & Basil Gunn N7NIX

## Files

These files are found in /etc/svxlink

* svxlink.conf
* gpio.con

This file is found in /etc/svxlink/svxlink.d

* ModuleEchoLink.conf

## Configuration Notes

* I found the [svxlink wiki InstallSrcHwRpi](https://github.com/sm0svx/svxlink/wiki/InstallSrcHwRpi) entries helpful.
  * Scroll down to __Problems (and fixes) along the way__ section
* The last variable changed to enable working on repeater was RGR_SOUND_DELAY=-1 in the [SimplexLogic] section of svxlink.conf
  * RGR_SOUND_DELAY=50 -> -1


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
