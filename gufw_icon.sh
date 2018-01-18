#!/usr/bin/env bash

# create a FIFO file, used to manage the I/O redirection from shell
PIPE=$(mktemp -u --tmpdir ${0##*/}.XXXXXXXX)
mkfifo $PIPE

# attach a file descriptor to the file
exec 3<> $PIPE

# add handler to manage process shutdown
function on_exit() {
    echo "quit" >&3
    rm -f $PIPE
}
trap on_exit EXIT

# add handler for tray icon left click
function on_click() {
    gufw
}
export -f on_click

# Based on script from bahamas10 https://gist.github.com/bahamas10
# https://gist.github.com/bahamas10/4d43660926bde28552db.js
# simple bash script to simulate JavaScript's setInterval (blocking)
#
# Author: Dave Eddy <dave@daveeddy.com>
# Date: September 27, 2014
# License: MIT

setInterval() {
	local func=$1
	local sleeptime=$2
	local _start _end _delta _sleep
	while true; do
		_start=$(date +%s)
		#echo "$_start: starting work"

		# do work (unknown amount of time)
		"$func"

		_end=$(date +%s)
		_delta=$((_end - _start))
		_sleep=$((sleeptime - _delta))
		#echo "$_end: finished doing work, took $_delta seconds, sleeping for $_sleep seconds"
		sleep "$_sleep"
	done
}

ufw_enable() {
	killall yad 2>/dev/null
    	# create the notification icon
    	yad --notification               \
        	--listen                     \
       		--image="security-high"      \
        	--text="UFW is enabled"   \
        	--command="bash -c on_click" <&3 &
}
ufw_disable() {
    	killall yad 2>/dev/null
    	# create the notification icon
    	yad --notification               \
        	--listen                     \
        	--image="security-low"      \
        	--text="UFW is disabled"   \
        	--command="bash -c on_click" <&3 &

}
ufw_set_mode() {
	cat /etc/ufw/ufw.conf | grep -wq ENABLED=yes
	if [ $? -eq 0 ]
	then
		ufw_enable	
	else
		ufw_disable
	fi
	firstime=false	
}

firstime=true
status=$(cat /etc/ufw/ufw.conf | grep -w ENABLED=yes)
dowork() {
	echo -n 'doing work... '
	if [ "$firstime" = true ]
	then
		ufw_set_mode
	else
		newstatus=$(cat /etc/ufw/ufw.conf | grep -w ENABLED=yes)		
		if [ "$status" != "$newstatus" ]
		then
			status=$(cat /etc/ufw/ufw.conf | grep -w ENABLED=yes)
			ufw_set_mode
		fi		
   	fi
	echo 'done'
}

# setInterval for 5 seconds.  in this example, because `dowork` takes 2 seconds to run,
# it will be called every 3 seconds, for a total of 5 seconds elapsed time.
echo "starting loop, will sleep 5 seconds between iterations"
setInterval dowork 5

