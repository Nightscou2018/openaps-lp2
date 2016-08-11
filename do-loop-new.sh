#!/bin/bash
SHELL=/bin/bash
PATH=/home/pi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games

START=`date +%s`

function error_exit
{
	END=`date +%s`
	ELAPSED=$(( $END - $START ))
	echo "$1" 1>&2
	logger -t do-loop-error "LOOP FAIL $1"
	logger -t do-loop-end "OPENAPS-LP LOOP ERROR EXIT ($ELAPSED seconds)"
        exit 1
}

cd /home/pi/openaps-lp

logger -t do-loop-start "OPENAPS-LP LOOP START"

if ! oref0 fix-git-corruption; then
	logger -t do-loop-start "GIT CORRUPTION FOUND - Attempting fix"
	if ! ./scripts/git-reclone.sh; then
		error_exit "GIT RECLONE FAIL"
	fi
else
	logger -t do-loop-start "PREFLIGHT"
	preflight_timeout=$((SECONDS+120))
        until openaps preflight;
        do
                if [ $SECONDS -gt $preflight_timeout ]; then
			error_exit "PREFLIGHT TIMEOUT ERROR"
		fi
		sleep 10
		logger -t do-loop-start "PREFLIGHT WAITING"
        done

	# Update if missing
	if ! grep -q maxBasal settings/settings.json; then
        	logger -t do-loop-start "GET PUMP SETTINGS"
		{ openaps get-settings || error_exit "get-settings"; } 2>&1 > >(logger -t do-loop-start)
	fi

        # Main loop
	openaps gather-clean-data |& logger -t do-loop-gather
        { openaps do-oref0 || error_exit "do-oref0"; } 2>&1 > >(logger -t do-loop-predict)
        { openaps enact-oref0 || error_exit "enact-oref0"; } 2>&1 > >(logger -t do-loop-enact)

	# Update nightscout
	{ openaps get-basal-status || error_exit "get-pump-updates"; } 2>&1 > >(logger -t do-loop-status)
	{ openaps upload-treatments || error_exit "upload-treatments"; } 2>&1 > >(logger -t do-loop-status)
	{ openaps upload-status || error_exit "upload-status"; } 2>&1 > >(logger -t do-loop-status)
fi

END=`date +%s`
ELAPSED=$(( $END - $START ))
logger -t do-loop-end "OPENAPS-LP LOOP SUCCESS ($ELAPSED seconds)"
