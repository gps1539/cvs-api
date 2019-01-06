#! /bin/bash

# script to create and mount a NetApp Cloud Volume and display time taken
# Written by Graham Smith, NetApp Oct 2018
# requires bash, jq and curl
# Version 0.0.2

#set -x

usage() { echo "Usage: $0 [-m <mountpoint> ] [-a <endpoint-ip> ] [-r <region> ] [-s <server-dns> ] [-u username ] [-p <pem-file> ] [-c <config-file>]" 1>&2; exit 1; }

while getopts ":m:a:r:s:u:p:c:" o; do
    case "${o}" in
        m)
            m=${OPTARG}
            ;;
        a)
            a=${OPTARG}
            ;;
	r)
	    r=${OPTARG}
            ;;
        s)
            s=${OPTARG}
            ;;
        u)
            u=${OPTARG}
            ;;
        p)
            p=${OPTARG}
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

if [ -z "${m}" ] || [ -z "${a}" ] || [ -z "${r}" ] || [ -z "${s}" ] || [ -z "${u}" ] || [ -z "${p}" ] || [ -z "${c}" ]; then
    usage
fi

#if [ $r != "us-east" ] && [ $r != "us-west" ]; then
#    usage
#fi

source $c

#echo $m $s $p $c $a $r

echo
echo "Mountpoints before creating new volume"
echo

ssh -i $p $u@$s 'sudo umount /mnt/test1 2>/dev/null; sudo showmount -e' $a

if [[ $? -ne 0 ]]; then 
	echo "Please check the pem file and server dns are correct"
	exit
fi

# create volume
echo
echo "Creating a Cloud Volume"
echo 

#Start timer
start=$(date +%s%N)

sh ./create-cv.sh -n $m -m $m -r $r -l extreme -a 100000 -e 172.0.0.0/8 -w rw -p nfs3 -t api-test -c ./$c

# mount volume
echo
echo "Mounting the volume"
sleep 4

ssh -i $p $u@$s 'sudo mount -t nfs -o rw,hard,nfsvers=3,tcp' $a':/'$m' /mnt/test1' 2>/dev/null

# test if successful
error=$?

# retry until mount
while [[ $error -ne 0 ]]; do
	sleep 1
	ssh -i $p $u@$s 'sudo mount -t nfs -o rw,hard,nfsvers=3,tcp' $a':/'$m' /mnt/test1' 2>/dev/null
	error=$?
done

# proved it mounted

end=$(date +%s%N)
time=$(bc -l <<< $end-$start)
time=$(echo "scale=4; $time/1000000000" | bc -l)

echo "The Cloud Volume is created and mounted in" $time "seconds"
echo

ssh -i $p $u@$s 'sudo df -ht nfs'
echo

ssh -i $p $u@$s 

# delete after testing
echo "Deleting volume " $m
sh ./delete-cv.sh -m $m -c ./$c > /dev/null 2>&1
