#!/bin/bash
# perform shutdown on all nodes on the soc network 172.27.1.*
# except head node, which is assumed to have IP address 172.27.1.2

HEAD=172.27.1.2

if [ "$EUID" -ne 0 ]
then 
    echo "Please run as sudo head-node"
    exit 1
fi

echo "DETECTING ALL WORKERS"
WORKERS=`nmap -sn $HEAD/24 | sed -n -e "/$HEAD/d" -e "/Nmap scan report for /s///p"`

if test -n "$WORKERS"
then echo "Workers found:  $WORKERS"
else echo "No workers found"
fi

for w in $WORKERS
do  ssh-keygen -R $w 2>&1 | egrep -v "# Host $h found|$HOME/.ssh/known_hosts updated|Original contents retained as $HOME/.ssh/known_hosts.old"
    ssh pi@$w sudo shutdown -h now
done


