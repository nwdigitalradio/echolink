#!/bin/bash
#
# This sets ALSA sound card config for a svxlink/echolink

scriptname="`basename $0`"
asoundstate_file="/var/lib/alsa/asound.state"

amixer -c udrc -s << EOF
# Set input and output levels for a TM-V71a
# Need to damp settings way down for ok deviation
#
sset 'PCM' -8.0dB
sset 'ADC Level' -5.0dB
sset 'LO Driver Gain' -6.0dB

#  Turn on AFOUT
sset 'CM_L to Left Mixer Negative Resistor' '10 kOhm'
sset 'IN1_L to Left Mixer Positive Resistor' '10 kOhm'

#  Turn on DISCOUT
sset 'CM_R to Right Mixer Negative Resistor' '10 kOhm'
sset 'IN1_R to Right Mixer Positive Resistor' '10 kOhm'

#  Turn off unnecessary pins
sset 'IN1_L to Right Mixer Negative Resistor' 'Off'
sset 'IN1_R to Left Mixer Positive Resistor' 'Off'
sset 'IN2_L to Left Mixer Positive Resistor' 'Off'
sset 'IN2_L to Right Mixer Positive Resistor' 'Off'
sset 'IN2_R to Left Mixer Negative Resistor' 'Off'
sset 'IN2_R to Right Mixer Positive Resistor' 'Off'
sset 'IN3_L to Left Mixer Positive Resistor' 'Off'
sset 'IN3_L to Right Mixer Negative Resistor' 'Off'
sset 'IN3_R to Left Mixer Negative Resistor' 'Off'
sset 'IN3_R to Right Mixer Positive Resistor' 'Off'

sset 'Mic PGA' off
sset 'PGA Level' 0

# Disable and clear AGC
sset 'ADCFGA Right Mute' off
sset 'ADCFGA Left Mute' off
sset 'AGC Attack Time' 0
sset 'AGC Decay Time' 0
sset 'AGC Gain Hysteresis' 0
sset 'AGC Hysteresis' 0
sset 'AGC Max PGA' 0
sset 'AGC Noise Debounce' 0
sset 'AGC Noise Threshold' 0
sset 'AGC Signal Debounce' 0
sset 'AGC Target Level' 0
sset 'AGC Left' off
sset 'AGC Right' off

# Turn off High Power output
sset 'HP DAC' off
sset 'HP Driver Gain' 0
sset 'HPL Output Mixer L_DAC' off
sset 'HPR Output Mixer R_DAC' off
sset 'HPL Output Mixer IN1_L' off
sset 'HPR Output Mixer IN1_R' off

#  Turn on the LO DAC
sset 'LO DAC' on

#  Turn on AFIN
sset 'LOL Output Mixer L_DAC' on

#  Turn on TONEIN
sset 'LOR Output Mixer R_DAC' on
EOF

stateowner=$(stat -c %U $asoundstate_file)
if [ $? -ne 0 ] ; then
   "$scriptname: Command 'alsactl store' will not work, file: $asoundstate_file does not exist"
   exit
fi

ALSACTL="alsactl"
if [[ $EUID != 0 ]] ; then
   ALSACTL="sudo alsactl"
fi

$ALSACTL store
if [ "$?" -ne 0 ] ; then
    echo "ALSA mixer settings NOT stored."
fi
