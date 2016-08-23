#!/bin/bash -eu
SHELL=/bin/bash
PATH=/home/pi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games

START=`date +%s`

logger -t do-loop-start "OPENAPS-LP LOOP START"

cd /home/pi/openaps-lp2
# rm oref0-predict/oref0.json &>/dev/null
rm -f monitor/* &>/dev/null

if ! oref0 fix-git-corruption; then
	logger -t do-loop-start "GIT CORRUPTION FOUND - Attempting fix"
	if ! ./scripts/git-reclone.sh; then
		logger -t do-loop-error "GIT RECLONE FAIL"
		exit 1
	fi
else
	logger -t do-loop-start "LOOP PREFLIGHT"
	preflight_timeout=$((SECONDS+120))
        until openaps preflight;
        do
                if [ $SECONDS -gt $preflight_timeout ]; then
			logger -t do-loop-error "LOOP PREFLIGHT TIMEOUT ERROR"
			exit 1
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
	( openaps gather-clean-data && openaps do-oref0 && openaps enact-oref0 && openaps get-basal-status &&openaps upload-treatments && openaps upload-status ) 2>&1 | logger -t do-loop
fi

./print-loop-result.sh |& logger -t do-loop-result
END=`date +%s`
ELAPSED=$(( $END - $START ))
logger -t do-loop-end "OPENAPS-LP LOOP SUCCESS ($ELAPSED seconds)"
