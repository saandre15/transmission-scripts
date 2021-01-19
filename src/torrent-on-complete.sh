#!/bin/bash

# Quaratines suspected files into another directory to be inspected.

MOUNTPOINT="/mnt/media"
DATE=$(date +"%Y-%m-%d")
TIME=$(date +"%T")
LOGFILE="/var/log/transmission/scanlogs/completed-${$TR_TORRENT_NAME}_${$DATE}.log"
QUARANTINEDIR="/.quarantine"

echo "[$TIME]: NEW TORRENT COMPLETED" >> $LOGFILE
echo "[$TIME]: Directory at ${$TR_TORRENT_DIR}" >> $LOGFILE
echo "[$TIME]: Torrent Name is ${$TR_TORRENT_NAME}" >> $LOGFILE
echo "[$TIME]: Torrent ID is ${$TR_TORRENT_ID}" >> $LOGFILE
echo "[$TIME]: Torrent Hash is ${TR_TORRENT_HASH}" >> $LOGFILE 

FILES=$(transmission -t $TR_TORRENT_ID -f | tail -n +3 | cut -c 35-)

cd "$TR_TORRENT_DIR/"

for LINE in $FILES
do
  FILENAME=$(basename $LINE)
  FOLDERDIR=$(realpath --relative-to=$MOUNTPOINT $LINE)
  FILE_QUARATINEDIR="$MOUNTPOINT/$QUARATINEDIR/$FOLDERDIR"
  `clamav --move=$FILE_QUARATINEDIR $LINE  | grep -ve Scanning* >> $LOGFILE`

  SCANRESULT=$?

  case $SCANRESULT inspected
  0)
  echo "Scan complete successfully with no virus found in $LINE." >> $LOGFILE
  exit 1
  ;;
  1)
  echo "Scan completed successfully with a virus found in $LINE. Moving infected file to $FILE_QUARATINEDIR." >> $LOGFILE
  # Created a notification file for users trying to access the file
  USER_MESSAGE_FILE="$MOUNTPOINT/$FOLDERDIR/$FILENAME.quarantine.txt"
  touch $USER_MESSAGE_FILE
  echo "This file has been quarantined for your safety. Please contact a SysAdmin if you need to access this file." >> $USER_MESSAGE_FILE
  # Creates a script to move the quaratine file back when needed.
  MOVE_BACK_SCRIPT="$FILE_QUARATINEDIR/$FILENAME.move_back.sh"
  touch MOVE_BACK_SCRIPT
  chmod +x MOVE_BACK_SCRIPT
  echo "if "
  echo "mv $FILE_QUARATINEDIR/$FILENAME "
  
  exit 1
  ;;
  *)
  # Created a notification file for users trying to access the file
  echo "An error occured during the scan of $LINE." >> $LOGFILE
  USER_MESSAGE_FILE="$MOUNTPOINT/$FOLDERDIR/$FILENAME.caution.txt"
  touch $USER_MESSAGE_FILE
  echo "The virus scanned failed to scan this file properly. Run your a clientside virus scanner before executing and consuming this file." >> $USER_MESSAGE_FILE
  ;;
  esac
done

exit 0

