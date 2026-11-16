#!/bin/bash

###################################################################
#script name    :vm_safetyrope.sh
#description    :run query to determine systems in the vm safetyrope policies and email out the info.
#date           :03/15/2024
#author         :matthew stankiewicz
#email          :matthew_stankiewicz@domain.com
#version        :1.0
###################################################################

# Store the absolute path of the script directory in a variable
script_dir=$(realpath $(dirname $0))

#email="$script_dir"/mail.restore
vm_policies="$script_dir"/vm_policies.txt
vm_count="$script_dir"/vm_count.txt
vm_mail="$script_dir"/vm_mail.txt

/usr/openv/netbackup/bin/admincmd/bppllist | grep 'vm_nbu' > $vm_policies

while IFS= read -r line
do
        # display $line or do somthing with $line
        count=$(/usr/openv/netbackup/bin/nbdiscover -noxmloutput -policy "$line" -noreason | grep + | wc -l)
        printf "%s\n", "$line = $count Clients   "
done <"$vm_policies" > $vm_count
cat $vm_count | tr -d , > $vm_mail

echo "" >> $vm_mail

policyprod=vm_nbu_safetyrope_prod

echo "Clients for policy $policyprod are below." >> $vm_mail

/usr/openv/netbackup/bin/nbdiscover -noxmloutput -includedonly -policy $policyprod >> $vm_mail

echo " " >> $vm_mail
echo " " >> $vm_mail

policydst=vm_nbu_safetyrope_dst

echo "Clients for policy $policydst are below." >> $vm_mail

/usr/openv/netbackup/bin/nbdiscover -noxmloutput -includedonly -policy $policydst >> $vm_mail

echo "" >> $vm_mail
echo "" >> $vm_mail

policymgmt=vm_nbu_safetyrope_mgmt

echo "Clients for policy $policymgmt are below." >> $vm_mail

/usr/openv/netbackup/bin/nbdiscover -noxmloutput -includedonly -policy $policymgmt >> $vm_mail

echo "" >> $vm_mail
echo $HOSTNAME >> $vm_mail

mail -s "nbu flex vm count per policy" receiver@domain.com < $vm_mail
