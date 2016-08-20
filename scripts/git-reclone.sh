SHELL=/bin/bash
PATH=/home/pi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games

logger -t git-reclone "GIT RECLONE START"

##
# Paths in this script are relative to home direcotry
#

cd /home/pi
if [ $? -ne 0 ]; then
        logger -t git-reclone "GIT RECLONE FAIL - Home dir."
        exit 1
fi

CORRUPTDIR="/home/pi/corrupt_repos"
BACKUPDIR="$(CORRUPTDIR)/repo_$$"
REPONAME="openaps-lp2"

mkdir $CORRUPTDIR |& logger -t git-reclone
rm -rf $BACKUPDIR |& logger -t git-reclone
mkdir $BACKUPDIR |& logger -t git-reclone
mv $REPONAME/* $BACKUPDIR  |& logger -t git-reclone

rm -rf openaps-lp2 |& logger -t git-reclone
if [ $? -ne 0 ]; then
        logger -t git-reclone "GIT RECLONE FAIL - rm openaps-lp"
        exit 1
fi

git clone https://github.com/bfaloona/openaps-lp2.git |& logger -t git-reclone
if [ $? -ne 0 ]; then
        logger -t git-reclone "GIT RECLONE FAIL - git clone"
        exit 1
fi

cp openaps-lp-assets/pump2.ini openaps-lp2/pump.ini |& logger -t git-reclone
cd openaps-lp2

git status > /dev/null
if [ $? -eq 0 ]; then
	logger -t git-reclone "GIT RECLONE END"
else
	logger -t git-reclone "GIT RECLONE FAIL - git status"
	exit 1
fi
