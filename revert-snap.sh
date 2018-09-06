#! /bin/bash

# script to revert to a snapshot of a NetApp Cloud Volume by mountpoint and snapshotId
# Written by Graham Smith, NetApp July 2018
# requires bash, jq and curl
# Version 0.0.1

#set -x

usage() { echo "Usage: $0 [-m <mountpoint> ] [-s <last|snapshotId> ] [-c <config-file>]" 1>&2; exit 1; }

while getopts ":m:s:c:" o; do
    case "${o}" in
        m)
            m=${OPTARG}
            ;;
	s)
	    s=${OPTARG}
            ;;
        c)
            c=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${m}" ] || [ -z "${s}" ] || [ -z "${c}" ]; then
    usage
fi

source $c

# get filesystem info
filesystems=$(curl -s -H accept:application/json -H "Content-type: application/json" -H api-key:$apikey -H secret-key:$secretkey -X GET $url/v1/FileSystems)

# get filesystemIds
ids=$(echo $filesystems |jq -r ''|grep fileSystemId |cut -d '"' -f 4)

if [ "${#ids}" == "0" ]; then
	echo "Please check that the apikey and secretkey are valid"
	exit
fi

# Find matching filesystemId
fileSystemId=$(echo $filesystems |jq -r ''| grep -i -B 10 $m |grep fileSystemId | cut -d '"' -f 4)

if [ "${#fileSystemId}" == "0" ]; then
	echo "Please check the mountpoint is correct"
	exit
fi

# if $s = last, find the Id of the last snapshot
if [ $s == "last" ];then
	snapshots=$(curl -s -H accept:application/json -H "Content-type: application/json" -H api-key:$apikey -H secret-key:$secretkey -X GET $url/v1/FileSystems/$fileSystemId/Snapshots)
	s=$(echo $snapshots | jq -r ''|grep snapshotId |tail -1 | cut -d '"' -f 4)
    echo $s
fi

# get region
region=$(echo $filesystems |jq -r '' | grep -i -B 1 $m |grep region |cut -d '"' -f 4)

# Revert snapshot
snapshot=$(curl -s -H accept:application/json -H "Content-type: application/json" -H api-key:$apikey -H secret-key:$secretkey -X POST $url/v1/FileSystems/$fileSystemId/Revert -d '
{"snapshotId": "'$s'",
"fileSystemId": "'$fileSystemId'",
"region": "'$region'"}'
)

echo $snapshot | jq 
