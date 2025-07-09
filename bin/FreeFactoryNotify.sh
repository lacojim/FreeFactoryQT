#!/bin/bash
#############################################################################
#               This code is licensed under the GPLv3
#    The following terms apply to all files associated with the software
#    unless explicitly disclaimed in individual files or parts of files.
#
#                           Free Factory
#
#                          Copyright 2013-2025
#                               by
#                     Jim Hines and Karl Swisher
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#  Script Name: FreeFactoryNotify.sh
#
#  This script accepts the three variables piped by intofywait
#  and then passes two of them, the directory path and the file
#  name file to FreeFactoryConversion.tcl script.
#############################################################################
LOG=/var/log/FreeFactory/FreeFactoryNotifyError.log
####################################################################################
# Clear variables to null value
SOURCEPATH=
NOTIFY_EVENT=
FILENAME=
#LASTSOURCEPATH=
#LASTFILENAME=
#FILESIZE=0
#LASTFILESIZE=0
####################################################################################
# Set up continuous loop.
for (( ; ; ))
do
####################################################################################
# Read variables piped in from inotifywait
	read SOURCEPATH NOTIFY_EVENT FILENAME
# Get file size to compare when the file is completely written.
#	sleep 5
#	FILESIZE=$(stat -c%s "$SOURCEPATH$FILENAME")
# This loop repeats the above procedure until the file
# size does not change.
#	while [ $FILESIZE -ne $LASTFILESIZE ]
#	do
#		sleep 3
#		LASTFILESIZE=$FILESIZE
#		FILESIZE=$(stat -c%s "$SOURCEPATH$FILENAME")
#		sleep 2
#	done
# Checking for dot files
 	if [ "${FILENAME:0:1}" != "." ]; then
####################################################################################
# Write variables to the stdout which is screen
		echo ""
		echo "*****************************************************************************************"
		echo "********************************* Report From *******************************************"
		echo "***************************** FreeFactoryNotify.sh **************************************"
		echo "============ Received the following variables from inotifywait"
		echo "============ Directory path and filename $SOURCEPATH$FILENAME"
		echo "============ Inotify Event   $NOTIFY_EVENT"
		/opt/FreeFactory/bin/FreeFactoryConversion.tcl $SOURCEPATH $FILENAME 2>> $LOG &
		echo "============ Running Free Fractory conversion script."
		echo "============ Converting $SOURCEPATH$FILENAME"
		echo "*****************************************************************************************"
		echo "*****************************************************************************************"
	fi
#
# End Apple work around.
#
####################################################################################
# Clear variables to null value
	SOURCEPATH=
	NOTIFY_EVENT=
	FILENAME=
# ===== END ==========
# End continuous loop
done
# Exit script.
exit
