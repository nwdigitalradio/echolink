#!/bin/bash
#
# List, Add & Remove call signs from
# "ACCEPT" lists in svxlink EchoLink module conf file.
#
# Usage:
#  listmgr.sh [-a callsign] [-d|-r callsign] [-l|-s]
#

CFG_DIR="/etc/svxlink/svxlink.d"
#CFG_DIR="/home/gunn/tmp"
CFG_FILE="ModuleEchoLink.conf"

# ===== function usage

function usage() {
   echo "Usage: $scriptname  [-a] [-d|-r] [-l|-s]" >&2
   echo "   -a callsign    Add a callsign to white list."
   echo "   -d|r callsign  Delete a callsign from white list."
   echo "   -l|s           List all callsigns in white list"
   echo "   -h|-?          Display this message"
}

# ===== function rootcheck()

function rootcheck() {
# Check if running with root privilege
if [[ $EUID != 0 ]] ; then
   echo "Must be root to write EchoLink file"
   exit 1
fi
}

# ===== function add_callsign()

function add_callsign() {

# Make all alpha chars upper case
callsign=$(echo "$1" | tr '/a-z/' '/A-Z/')
echo "Adding callsign: $callsign"

# check if callsign is all ready in the incoming list
incoming=$(grep "^ACCEPT_INCOMING" "$CFG_DIR/$CFG_FILE")

grep -q $callsign <<< $incoming
if [ $? -eq 0 ] ; then
   # Already in list, so no editing required
   echo "Callsign: $callsign already in incoming list"
else
   # Add callsign to list
   echo "Adding callsign: $callsign to incoming list"
   sed -i -e "/ACCEPT_INCOMING/ s/)/|$callsign)/" "$CFG_DIR/$CFG_FILE"
fi

# check if it's all ready in the outgoing list
outgoing=$(grep "^ACCEPT_OUTGOING" "$CFG_DIR/$CFG_FILE")

grep -q $callsign <<< $outgoing
if [ $? -eq 0 ] ; then
   # Already in list, so no editing required
   echo "Callsign: $callsign already in outgoing list"
else
   # Add callsign to list
   echo "Adding callsign: $callsign to outgoing list"
   sed -i -e "/ACCEPT_OUTGOING/ s/)/|$callsign)/" "$CFG_DIR/$CFG_FILE"
fi

}

# ===== function remove_callsign()

function remove_callsign() {

# Make all alpha chars upper case
callsign=$(echo "$1" | tr '/a-z/' '/A-Z/')
echo "Removing callsign: $callsign"

# check if callsign is NOT in the incoming list
incoming=$(grep "^ACCEPT_INCOMING" "$CFG_DIR/$CFG_FILE")

grep -q $callsign <<< $incoming
if [ $? -eq 0 ] ; then
   # Already in list, so no editing required
   echo "Deleting callsign: $callsign in incoming list"
   sed -i -e "/ACCEPT_INCOMING/ s/$callsign//" "$CFG_DIR/$CFG_FILE"
else
   # Add callsign to list
   echo "Callsign: $callsign is NOT in incoming list"
fi

# check if it's all ready in the outgoing list
outgoing=$(grep "^ACCEPT_OUTGOING" "$CFG_DIR/$CFG_FILE")

grep -q $callsign <<< $outgoing
if [ $? -eq 0 ] ; then
   # Delete callsign in list
   echo "Deleting callsign: $callsign in outgoing list"
   sed -i -e "/ACCEPT_OUTGOING/ s/$callsign//" "$CFG_DIR/$CFG_FILE"
else
   # Already in list, so no editing required
   echo "Callsign: $callsign is NOT in outgoing list"
fi

# Remove duplicate |
   sed -i -e "/ACCEPT_INCOMING/ {s/||/|/;s/|)/)/;s/(|/(/}" "$CFG_DIR/$CFG_FILE"
   sed -i -e "/ACCEPT_OUTGOING/ {s/||/|/;s/|)/)/;s/(|/(/}" "$CFG_DIR/$CFG_FILE"
}

# ===== function list_callsigns()

function list_callsigns() {
   accept_list_in=$(grep "ACCEPT_INCOMING" "$CFG_DIR/$CFG_FILE" | cut -d'(' -f2 | cut -d ')' -f1)
   accept_list_out=$(grep "ACCEPT_OUTGOING" "$CFG_DIR/$CFG_FILE" | cut -d'(' -f2 | cut -d ')' -f1)
   if [ "$accept_list_in" != "$accept_list_out" ] ; then
      echo "INCOMING & OUTGOING white lists do not match ... exiting"
      echo "Incoming: $accept_list_in"
      echo "Outgoing: $accept_list_out"
      exit 1
   fi
   call_list=$(echo $accept_list_in)
   num_calls=$(grep -o "|" <<< "$call_list" | wc -l)

   echo "Callsign List ($((num_calls + 1)))"
   echo
for (( i=0; i<=$num_calls; i++ )) ; do
#      echo "debug: i=$i,num=$num_calls call_list $call_list"

      echo $(echo $call_list | cut -d'|' -f1)
       call_list=${call_list#*|}

      # sanity check
      if (( i > 50 )) ; then
         echo "Debug sanity check, number of callsigns %i exceeded."
         exit
      fi
   done
# Debug only
#   echo "White List: $accept_list_in"
}

# ===== main

# Check if svxlink ModuleEcho config file exists

if [ ! -f "$CFG_DIR/$CFG_FILE" ] ; then
   echo "Can't find EchoLink config file: $CFG_DIR/$CFG_FILE"
   exit 1
fi

if [[ $# -eq 0 ]] ; then
      list_callsigns
fi

# parse command line args
while [[ $# -gt 0 ]] ; do
key="$1"

case $key in
   -a|--add)
      rootcheck
      callsign="$2"
      shift # past argument
      if [ -z "$callsign" ] ; then
         echo "No callsign specified."
	 exit 1
      fi
      add_callsign $callsign
      echo
      grep "ACCEPT_INCOMING" "$CFG_DIR/$CFG_FILE"
      grep "ACCEPT_OUTGOING" "$CFG_DIR/$CFG_FILE"
   ;;

   -d|-r|--delete)
      rootcheck
      callsign="$2"
      shift # past argument
      if [ -z "$callsign" ] ; then
         echo "No callsign specified."
	 exit 1
      fi
      remove_callsign $callsign
      echo
      grep "ACCEPT_INCOMING" "$CFG_DIR/$CFG_FILE"
      grep "ACCEPT_OUTGOING" "$CFG_DIR/$CFG_FILE"
   ;;
   -l|-s)
      list_callsigns
   ;;

   -d|--debug)
      DEBUG=1
      echo "Debug mode on"
   ;;
   -h|--help|?)
      usage
      exit 0
   ;;
   *)
      # unknown option
      echo "Unknow option: $key"
      usage
      exit 1
   ;;
esac
shift # past argument or value
done


