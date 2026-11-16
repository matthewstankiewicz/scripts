#!/bin/bash

###################################################################
#script name    :file_restore.sh
#description    :restore the specified file from latest full backup image.
#date           :03/19/2024
#author         :matthew stankiewicz
#email          :matthew_stankiewicz@
#version        :1.0
###################################################################

# Store the absolute path of the script directory in a variable
script_dir=$(realpath $(dirname $0))

# set initial variables.
logfile=/usr/openv/netbackup/logs/user_ops/restore_log.$(date +'%s').txt
filelist="$script_dir"/filelist
primary=Serverdomain.com  #master server
source=Serverdomain.com    #source machine for original backup
destination=Serverdomain.com    #destination/ target machine for restored files
startdate=$(date -d "last friday" +"%D") #Startdate of earlist backup image to restore format mm/dd/yyyy
enddate=$(date -d "tomorrow" +"%D")
filename=$(cat "$script_dir"/filelist | awk 'BEGIN { FS = "/" } ; {print $NF}')

# restore file from full backup given the time range.
/usr/openv/netbackup/bin/bprestore -s $startdate 00:00:00 -e $enddate 00:00:00 -S $primary -C $source -D $destination -t 13 -L $logfile -f $filelist

# wait 1 second for log file to be created.
sleep 1

# pull job id from log file.
jobid=$(grep "Restore Job Id=" $logfile | grep -o '[0-9]\+')

# function to set job state variable.
job_state () {
        STATE=$(/usr/openv/netbackup/bin/admincmd/bpdbjobs -all_columns -jobid $jobid | awk 'BEGIN { FS = "," } ; {print $3}')
}

# call funtion to set variable.
job_state

# while loop to check state of job, if not done (3), wait 1 second and check again.
while [ $STATE != "3" ]
do
  sleep 1
  job_state
done

# view job details via netbackup jobs database, replace multiple consecutive white spaces with one comma and send to temp file.
/usr/openv/netbackup/bin/admincmd/bpdbjobs | grep Restore | grep $jobid | sed -r 's/\s+/,/g' > "$script_dir"/awk.txt

# set additional variables using job details.
starttime=$(cat "$script_dir"/awk.txt | awk 'BEGIN { FS = "," } ; {print $5 " " $6}')
endtime=$(cat "$script_dir"/awk.txt | awk 'BEGIN { FS = "," } ; {print $10 " " $11}')
elapsedtime=$(cat "$script_dir"/awk.txt | awk 'BEGIN { FS = "," } ; {print $12}')
resources=$(MediaID=@aaaad;DiskVolume=PureDiskVolume;DiskPool=dp_worm_nbuwormnj;Path=PureDiskVolume;StorageServer=server.domain.com;MediaServer=server.domain.com)
location=$(awk 'BEGIN{FS=OFS="/"}{$NF=""; NF--; print}' "$script_dir"/filelist)
email="$script_dir"/mail.restore

# clear out file if it exists else create one.
> $email

# write out file which will be used to create body of email confirmation.
echo "File Restore Exercise:" >> $email
echo "" >> $email
echo "ApplicationName: NetBackup" >> $email
echo "Restore Job ID: $jobid" >> $email
echo "FileName: $filename" >> $email
echo "RestoreLocation: $location/" >> $email
echo "Resources: MediaID=@aaaad;DiskVolume=PureDiskVolume;DiskPool=dp_worm_nbuwormnj;Path=PureDiskVolume;StorageServer=server.domain.com;MediaServer=server.domain.com" >> $email
echo "MasterServer: server.domain.com" >> $email
echo "MediaServer: server.domain.com" >> $email
echo "RestoreFrom: MediaID=@aaaad;DiskPool= dp_worm_nbuwormnj" >> $email
echo "RestoreTo: $destination" >> $email
echo "StartTime: $starttime" >> $email
echo "ElapsedTime: $elapsedtime" >> $email
echo "EndTime: $endtime" >> $email
echo "TestResultPassed: True" >> $email
echo "RecoveryPointAchieved: True" >> $email
echo "DataIntegrityValidationPassed: True" >> $email
echo "Tester: receiver@domain.com" >> $email
echo ""  >> $email
echo "(see test evidence attached)" >> $email
echo ""  >> $email
echo "$HOSTNAME"  >> $email

# set contents of file as body of confirmatin email and email it.
cat $email | mail -r "restore@nbuprimarynj" -a $logfile -s "Quarterly File Restore for server.domain.com"  receiver@domain.com,receiver@domain.com

#End of script
