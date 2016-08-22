#!/bin/bash -eu
SHELL=/bin/bash
PATH=/home/pi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games

START=`date +%s`

function error_exit
{
	END=`date +%s`
	ELAPSED=$(( $END - $START ))
	echo "$1" 1>&2
	logger -t do-loop-error "LOOP FAIL $1"
	./print-loop-result.sh |& logger -t do-loop-result
	logger -t do-loop-end "OPENAPS-LP LOOP ERROR EXIT ($ELAPSED seconds)"
        exit 1
}

logger -t do-loop-start "OPENAPS-LP LOOP START"

cd /home/pi/openaps-lp2
# rm oref0-predict/oref0.json &>/dev/null
rm -f monitor/* &>/dev/null

if ! oref0 fix-git-corruption; then
	logger -t do-loop-start "GIT CORRUPTION FOUND - Attempting fix"
	if ! ./scripts/git-reclone.sh; then
		error_exit "GIT RECLONE FAIL"
	fi
else
	logger -t do-loop-start "LOOP PREFLIGHT"
	preflight_timeout=$((SECONDS+120))
        until openaps preflight;
        do
                if [ $SECONDS -gt $preflight_timeout ]; then
			error_exit "LOOP PREFLIGHT TIMEOUT ERROR"
		fi
		sleep 10
		logger -t do-loop-start "LOOP PREFLIGHT WAITING"
        done

	# Update if missing
	if ! grep -q maxBasal settings/settings.json; then
        	logger -t do-loop-start "GET PUMP SETTINGS"
		( openaps get-settings; ) 2>&1 | logger -t do-loop-start
	fi

	# Simple loop
	# openaps do-everything |& logger -t do-everything

        # Main loop
	( openaps gather-clean-data; ) 2>&1 | logger -t do-loop-gather
	( openaps do-oref0; ) 2>&1 | logger -t do-loop-predict
        ( openaps enact-oref0; ) 2>&1 | logger -t do-loop-enact

	# Update nightscout
	( openaps get-basal-status; ) 2>&1 | logger -t do-loop-status
	( openaps upload-treatments; ) 2>&1 | logger -t do-loop-status
	( openaps upload-status; ) 2>&1 | logger -t do-loop-status
fi

./print-loop-result.sh |& logger -t do-loop-result
END=`date +%s`
ELAPSED=$(( $END - $START ))
logger -t do-loop-end "OPENAPS-LP LOOP SUCCESS ($ELAPSED seconds)"
