#!/bin/bash

# This Script Demotes a Head-node to a Worker-node 
# - - - - - - - - - - - - - - - - - - - - - - - - - - 

if [ "$EUID" -ne 0 ]
then 
    echo "Please run as sudo worker-node"
    exit 1
fi

# Removing export of /hd-cluster from /etc/exports
echo "RECONFIGURING /etc/exports"
sed -i 's+/hd-cluster 172.27.1.0/24(rw,sync,no_subtree_check)++g' /etc/exports

# Stopping export of /hd-cluster
## Exporting manually like this doesn't require a restart of the NFS server
##  and doesn't modify any other exports like running `exportfs -ua` would
echo "STOPPING /hd-cluster EXPORT"
exportfs -uo rw,sync,no_subtree_check 172.27.1.0/24:/hd-cluster

# Removing head-node static IP
echo "REMOVING STATIC IP ADDRESS"
sed -i 's+static ip_address=172.27.1.2/24++g' /etc/dhcpcd.conf

# Removing the empty line left behind by prior command
sed -i '/metric 301/,/static routers=172.27.1.1/{ /^[ \t]*$/d}' /etc/dhcpcd.conf

# Applying dhcpcd changes
echo "REBINDING ETH1 CONFIG"
dhcpcd --rebind eth1

# Remove known_hosts so that this node can become a head node for a different
#  cluster in the future without host key identification warnings
rm -f /hd-cluster/.ssh/known_hosts

# Remove hostfile so that lack of a hostfile can be used to detect standalone
# usage, e.g., in CSinParallel/Patternlets/mpi4py/run.py
rm -f /hd-cluster/hostfile

# Removing eth1 dhcp server config
echo "REMOVING ETH1 SERVER CONFIGURATION"
sed -i '/./{H;$!d} ; x ; /# BEGIN ETH1 BLOCK/,//d' /etc/dhcp/dhcpd.conf

# Removing interface eth1 from dhcp server
echo "REMOVING ETH1 INTERFACE" 
sed -i 's/INTERFACESv4="eth0 eth1"/INTERFACESv4="eth0"/g' /etc/default/isc-dhcp-server

# Restarting dhcp server 
echo "RESTARTING DHCP SERVER"
systemctl restart isc-dhcp-server
