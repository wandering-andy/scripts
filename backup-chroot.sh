#!/bin/bash

# Backup Script for Chroot
#########################

# chroot name as parameter
CHROOT=$1

# Error commands
# function yell() { echo "$0: $*" >&2; }
# function die() { yell "$*"; exit 111; }
# function try() { "$@" || die "cannot $*"; }

run() {
  cmd_output=$(eval $1)
  return_value=$?
  if [ $return_value != 0 ]; then
    echo "Command $1 failed"
    exit -1
  else
    echo "output: $cmd_output"
    echo "Command succeeded."
  fi
  return $return_value
}

# Check if input parameter was supplied
if [ $# -eq 0 ]
  echo "Backup failed. Please include the name of a chroot to backup."
  exit $?
fi

# Exit chroot if script is run from chroot
if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "Exiting chroot."
  deactivate
fi

# If chroot does not exist, throw error
if [ sh ~/Downloads/crouton -t help | grep $CHROOT ]
  echo "Chroot found."
else
  echo "Chroot was not found."
  exit $?

# Run back up command and get path of backup from output
BACKUP=`edit-chroot -b $CHROOT | grep -Eo "((\/\w+){5}([-]\w+)*\..*)$"`

# When back up completes, push to server
scp $BACKUP andy@imandyjones.com:/home/andy/chroot-backups

# When copy is complete, delete backup
rm -rf $BACKUP

# Display completion message
echo "$CHROOT was successfully backed up."
