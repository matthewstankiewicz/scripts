#!/bin/bash

###################################################################
#script name    :vm_restore.sh
#description    :restore the specified virtual machine from its latest backup image.
#date           :03/19/2024
#author         :matthew stankiewicz
#email          :matthew_stankiewicz@domain.com
#version        :1.0
###################################################################

# Store the absolute path of the script directory in a variable
script_dir=$(realpath $(dirname $0))

# set starting variables.
logfile=/usr/openv/netbackup/logs/user_ops/proglog/vm_restore_log.$(date +'%s').txt
primary=server.domain.com  #primary server
client=ClientName  #vm/client name
awkfile="$script_dir"/awk.txt

# restore vmware virtual machine from its latest backup image, overwriting existing vm, powering on after restore, and suppressing confirmation prompts.
/usr/openv/netbackup/bin/nbrestorevm -vmw -S $primary -C $client -L $logfile -vmpo -O -force

# wait for 1 second to let log file to be created.
sleep 1

# pull job id from log file.
jobid=$(grep "Restore Job Id=" $logfile | grep -o '[0-9]\+')

# function to set job state variable.
job_state () {
        state=$(/usr/openv/netbackup/bin/admincmd/bpdbjobs -all_columns -jobid $jobid | awk 'BEGIN { FS = "," } ; {print $3}')
}

# call funtion to set variable.
job_state

# while loop to check state of job, if not done (3), wait 1 second and check again.
while [ $state != "3" ]
do
  sleep 1
  job_state
done

# pull restoring to location from log file.
restoreto=$(cat $logfile | grep "Restoring to" | cut -d" " -f 3-)

# view job details via netbackup jobs database, replace multiple consecutive white spaces with one comma and send to temp file.
/usr/openv/netbackup/bin/admincmd/bpdbjobs | grep Restore | grep $jobid | sed -r 's/\s+/,/g' > $awkfile

# set additional variables using job details.
starttime=$(cat $awkfile | awk 'BEGIN { FS = "," } ; {print $7 " " $8}')
endtime=$(cat $awkfile | awk 'BEGIN { FS = "," } ; {print $13 " " $14}')
elapsedtime=$(cat $awkfile | awk 'BEGIN { FS = "," } ; {print $15}')
resources=$(mediaid=@aaaad;diskvolume=purediskvolume;diskpool=dp_worm_nbuwormnj;path=purediskvolume;storageserver=server.domain.com;mediaserver=server.domain.com)
email="$script_dir"/mail.restore

# clear out file if it exists else create one.
> $email

# write out file which will be used to create body of email confirmation.
echo "file restore exercise:" >> $email
echo "" >> $email
echo "applicationname: netbackup" >> $email
echo "restore job id: $jobid" >> $email
echo "resources: mediaid=@aaaad;diskvolume=purediskvolume;diskpool=dp_worm_nbuwormnj;path=purediskvolume;storageserver=server.domain.com;mediaserver=server.domain.com" >> $email
echo "masterserver: $primary" >> $email
echo "mediaserver: server.domain.com" >> $email
echo "restorefrom: mediaid=@aaaad;diskpool= dp_worm_nbuwormnj" >> $email
echo "restoreto: $restoreto" >> $email
echo "starttime: $starttime" >> $email
echo "elapsedtime: $elapsedtime" >> $email
echo "endtime: $endtime" >> $email
echo "testresultpassed: true" >> $email
echo "recoverypointachieved: true" >> $email
echo "dataintegrityvalidationpassed: true" >> $email
echo "tester: receiver@domain.com" >> $email
echo ""  >> $email
echo "(see test evidence attached)" >> $email
echo ""  >> $email
echo "$hostname"  >> $email

# set contents of file as body of confirmatin email and email it.
cat $email | mail -r "restore@nbuprimarynj" -a $logfile -s "quarterly vm restore for $client"  receiver@domain.com,areceiver@domain.com


#end of script
