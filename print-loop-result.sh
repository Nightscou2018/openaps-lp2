SHELL=/bin/bash
PATH=/home/pi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games

cd /home/pi/openaps-lp2
echo PROFILE && cat oref0-monitor/profile.json
echo IOB && cat oref0-monitor/iob.json
echo PREDICT && cat oref0-predict/oref0.json
echo ENACT && cat oref0-enacted/enacted-temp-basal.json
echo
echo NIGHTSCOUT && cat nightscout/openaps-status.json
