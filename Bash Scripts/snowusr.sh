#! /usr/bin/bash

###################################################################
#script name    :snowusr.sh
#description    :create snowusr account for purpose of ServiceNow discovey on linux system.
#date           :03/15/2024
#author         :matthew stankiewicz
#email          :matthew_stankiewicz@domain.com
#error checking :sean halford
#email          :sean_halford@domain.com
#version        :1.0
###################################################################

#set -eo pipefail

publickey=$( < ${PWD}/public )
username="snowusr"

#check if user already exists; remove password if true
id $username &> /dev/null
IDRES=$?
if [[ $IDRES -eq 0 ]]; then
        echo "user already exists"
        passwd --delete $username
else
        #Add user
        useradd -m -s /usr/bin/bash $username
        wait $!
        echo "User added"
        wait $!
fi

#check if .ssh dir exists and if not create
if [[ -d /home/$username/.ssh ]]; then
        echo ".ssh dir already exists"
else
        #Make user .ssh directory
        mkdir /home/$username/.ssh
        wait $!
        echo ".ssh directory created"
        wait $!
fi

#check if public key already added
PKGREP=$(grep -s "$publickey" /home/$username/.ssh/authorized_keys)
if [[ $PKGREP ]]; then
        echo "public key already present"
else
        #Add Public Key to authorized keys
        echo $publickey >> /home/$username/.ssh/authorized_keys
        wait $!
        echo "Public Key added to authorized_keys"
        wait $!
fi

#Change the owner and group of the /home/username/.ssh directory to the new user
chown -R $username:$username /home/$username/.ssh
wait $!
echo "Owner and group of /home/$username/.ssh changed to $username"
wait $!

# make sure only the new user has permissions
chmod 700 /home/$username/.ssh
chmod 600 /home/$username/.ssh/authorized_keys
wait $!
echo "Permissions Updated"
wait $!

#check for and Enable sudo privileges for the new user via sudoers.d file
SUDOCMDS="$username ALL=(root) NOPASSWD:/usr/sbin/dmidecode,/usr/sbin/lsof,/usr/sbin/ifconfig,/usr/sbin/fdisk,/usr/bin/multipath,/usr/sbin/dmsetup,/usr/bin/cat,/usr/bin/ls,/usr/bin/ps,/usr/bin/cut,/usr/sbin/lshw,/usr/bin/netstat,/etc/sbin/ss,/usr/bin/stat"
SUDOGREP=$(grep -s "$SUDOCMDS" /etc/sudoers.d/$username)
if [[ $SUDOGREP ]]; then
        echo "sudo rules already in place"
else
        echo $SUDOCMDS >> /etc/sudoers.d/$username
        echo "$username added to sudoers"
fi

#/usr/bin/echo "$username ALL=(root) NOPASSWD:/usr/sbin/dmidecode,/usr/sbin/lsof,/usr/sbin/ifconfig,/usr/sbin/fdisk,/usr/bin/multipath,/usr/sbin/dmsetup,/usr/bin/cat,/usr/bin/ls,/usr/bin/ps,/usr/bin/cut,/usr/sbin/lshw,/usr/bin/netstat,/etc/sbin/ss,/usr/bin/stat" >> /etc/sudoers.d/$username
#wait $!
#echo "$username added to sudoers"
#wait $!

#verify section
if [[ $(id $username | awk '{print $1}' | awk -F\( '{print $2}' | sed 's/)//') -eq $username ]]; then
        USERADDED="Pass"
else
        USERADDED="Fail"
        echo "User is not available on server"
        exit 1
fi
#insert additional validations here such as checking public key existence, dir perms, etc
