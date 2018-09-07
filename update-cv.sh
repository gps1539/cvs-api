#! /bin/bash

# script to update service level and allocated size of NetApp Cloud Volume by mountpoint
# Written by Graham Smith, NetApp Sept 2018
# requires bash, jq and curl
# Version 0.0.1

#set -x

usage() { echo "Usage: $0 [-m <mountpoint> ] [-s <standard|premium|extreme> ] [ -a allocated_size_in_GB (100 to 100000) ] [-c <config-file>]" 1>&2; exit 1; }

while getopts ":m:s:a:c:" o; do
    case "${o}" in
        m)
            m=${OPTARG}
            ;;
		s)
		    s=${OPTARG}
            ;;
		a)
		    a=${OPTARG}
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

if [ -z "${m}" ] || [ -z "${c}" ] || [ -z "${s}" ] || [ -z "${a}" ]; then
    usage
fi

if [ $s != "standard" ] && [ $s != "premium" ] && [ $s != "extreme" ]; then
    usage
fi

if [ $s = "standard" ]; then
    s=basic
fi

if [ $s = "premium" ]; then
    s=standard
fi

if [[ $a != ?(-)+([0-9]) ]]; then
    usage
fi

if (( $a < 100 || $a > 1000000 )); then
    usage
fi

a=$((a*1000000000))


source $c

time=$(date +%Y%m%d%H%M%S)

# get filesystem info
filesystems=$(curl -s -H accept:application/json -H "Content-type: application/json" -H api-key:$apikey -H secret-key:$secretkey -X GET $url/v1/FileSystems)

# get filesystemIds
ids=$(echo $filesystems |jq -r ''|grep fileSystemId |cut -d '"' -f 4)

if [ "${#ids}" == "0" ]; then
	echo "Please check that the apikey and secretkey are valid"
	exit 0
fi

# get region
region=$(echo $filesystems |jq -r '' | grep -i -B 1 $m |grep region |cut -d '"' -f 4)

# Find matching filesystemId
fileSystemId=$(echo $filesystems |jq -r ''| grep -i -B 10 $m |grep fileSystemId | cut -d '"' -f 4)

if [ "${#fileSystemId}" == "0" ]; then
	echo "Please check the mountpoint is correct"
	exit
fi

# Update
curl -s -H accept:application/json -H "Content-type: application/json" -H api-key:$apikey -H secret-key:$secretkey -X PUT $url/v1/FileSystems/$fileSystemId -d '{"creationToken": "'$m'","region": "'$region'","serviceLevel": "'$s'","quotaInBytes": '$a'}' | jq -r
