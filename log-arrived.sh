#!/bin/bash
##########################################################################################
#Script Name    :log-arrived.sh
#Description    :send alert mail when server receives a log files in a specified path
#Args           :n/a
#Author         :Jason McColl
#Email          :jason.mccoll@outlook.com
#Instructions	:Recommended that you store this in /scripts but can be placed anywhere
#				:DO NOT STORE in path_to_monitor location
#				:Consider putting the script in crontab to run as frequently as you need
#				:Create a schedule in crontab (BE EXTREMELY CAREFUL PLAYING WITH CRONTAB)
#					-Every minute		*/1 * * * * /scripts/log-arrived.sh
#					-Every hour			* */1 * * * /scripts/log-arrived.sh
#License		:GNU GPL-3	
#    			Copyright (C) 2018  Jason McColl
#
#    			This program is free software: you can redistribute it and/or modify
#    			it under the terms of the GNU General Public License as published by
#    			the Free Software Foundation, either version 3 of the License, or
#    			(at your option) any later version.
#
#    			This program is distributed in the hope that it will be useful,
#   			but WITHOUT ANY WARRANTY; without even the implied warranty of
#    			MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#				GNU General Public License for more details.
#Version		:v1.0 - Created
#				:v1.1 - Added License information
##########################################################################################

##############################     VARIABLES TO MODIFY      ##############################

homeserver="your server name here"		#Enter name of host server here for clarification
path_to_monitor="/tmp/test/"           	#Modify this value for your environment
tmp_path="/tmp"							#Modify this value for your environment - default is /tmp
path_to_logs="/tmp/output"				#Storage location for historical logs
endtime="22" 							#This can be modified to when you want the last report emailed
from="server@your.company.com"			#Ensure address domaain is authenticated or relayable
to="recipient@your.company.com"			#Best to use a distribution group address

##############################       FIXED  VARIABLES       ##############################

now=`date +%k`
today=`date +%F`
oldsize=`cat $path_to_logs/baseline.txt`
newsize=`ls -l $path_to_monitor | grep total | awk '{print $2}'`
baselinefile="$path_to_logs/baseline.txt"
logfile="$path_to_logs/log-arrived.$today.log"
lastfile=`ls -Art $path_to_monitor | tail -n 1`
subject1="Server System Log Status Alert"
subject2="Somethings gone wrong in $path_to_monitor on $homeserver, the new path is smaller than the old path"
subject3="Server System Log Status Report for $today"
subject4="Fatal Error - The path to monitor is not existing"

##############################       LOGFILE  STRINGS       ##############################
logstring0="====================================="
logstring1="Initialising..."
logstring2="Syslog report file - `date`"
logstring3="Endtime reached - sending email with report."
logstring4="Baseline reference file"
logstring5="Sending email..."
logstring6="Creating directory $path_to_logs"
logstring7="==============="
logerror0="The path you selected to monitor does not exist"

##############################            SCRIPT            ##############################

### Checking if Logging path exists

if [ ! -d "$path_to_logs" ]
then
	mkdir $path_to_logs
	sleep 2
fi

### Checking existence of path to monitor

if [ ! -d "$path_to_monitor" ]
then
	echo $logerror0 >> $logfile
    printf "$logerror0 - The path you have selected either\n-Does not exist\nHas been deleted\nPath: $path_to_monitor/nServer: $homeserver\n" | mailx -s "$today - $subject4" -r "$from" "$to"
	exit 0
fi

### Checking for existence of current log, will create if it does not exist

if [ -e $path_to_logs/log-arrived.$today.log ]
then
	echo $logstring7 >> $logfile
	if [ "$now" -gt "$endtime" ]
	then  
		echo "Moving logfile to $path_to_logs/yesterday.log" >> $logfile
		echo $logstring3 >> $logfile 
		echo $logstring3 | mailx -a "$logfile" -s "$today - $subject3" -r "$from" "$to"
		sleep 3
		### If you want to leave the logs in the /tmp folder hash out the below four lines
		echo "Moving logfile to $path_to_logs/yesterday.log"
		mv $logfile $path_to_logs/yesterday.log
		sleep 10								
		exit 0									
	else
		date +%F" "%H":"%M >> $logfile
	fi

### Creating logfile header
	
else
	touch $logfile
	echo "$logstring0" >> $logfile
	echo "$logstring2" >> $logfile
	echo "$logstring0" >> $logfile
	echo "$logstring1" >> $logfile
	date +%F" "%H":"%M >> $logfile
	echo "$logstring7" >> $logfile
fi

### Checking if baseline file exists

if [ -e $baselinefile ]
then
        echo "$logstring4 exists" >> $logfile
else
		ls -l $path_to_monitor | grep total | awk '{print $2}' > $path_to_logs/baseline.txt
        echo "$logstring4 does not exist --- exiting immediately" >> $logfile
        printf "$logstring4 - Missing\nThis file will be available for the next scheduoled run.\n" | mailx -a "$lastfile" -s "$today - $subject1" -r "$from" "$to"
		exit 0
fi

### Comparing baseline file against previous size

if [ "$newsize" == "$oldsize" ]
then
        echo "No change" >> $logfile
else
        if [ "$newsize" -gt "$oldsize" ]
        then
				### Email will be sent if new files have been detected in path_to_monitor
				ls -l $path_to_monitor | grep total | awk '{print $2}' > $path_to_logs/baseline.txt
                echo "$logstring5 - Newsize is greater" >> $logfile 
                printf "$logstring5 - New Files have been detected\n\nCheck in the following location $path_to_monitor for $lastfile\n" | mailx -s "$today - $subject1" -r "$from" "$to"
        else
				### Email will be sent if size of path_to_monitor has decreased - Files deleted etc
                ls -l $path_to_monitor | grep total | awk '{print $2}' > $path_to_logs/baseline.txt
				echo "$logstring5 - Somethings gone wrong on $homeserver, the new path is smaller than the old path" >> $logfile 
                printf "$logstring5 - Somethings gone wrong on $homeserver/nThere seems to be less files in your path" | mailx -s "$subject2" -r "$from" "$to"
        fi
fi
echo "Exiting" >> $logfile
exit 0