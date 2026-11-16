#!/bin/bash
read -p "Enter master server name : " mastername
read -p "Enter policy name : " policyname
echo "Details for policy $policyname are below."
/usr/openv/netbackup/bin/admincmd/bppllist $policyname -U -M $mastername | egrep -v "Active:|Effective date:|Mult. Data Streams:|Client Encrypt:|Checkpoint:|Policy Priority:|Max Jobs/Policy:|Disaster Recovery:|Collect BMR info:|Volume Pool:|Server Group:|Keyword:|Data Classification:|Residence is Storage Lifecycle Policy:|Application Discovery:|Discovery Lifetime:|ASC Application and attributes:|Granular Restore Info:|Ignore Client Direct:|Use Accelerator:|Client List Type:|Selection List Type:|Application Defined:|PFI Recovery:|Maximum MPX:|Fail on Error:|Number Copies:|Synthetic:|Checksum Change Detection:|Backup network drvs:|Collect TIR info:"
