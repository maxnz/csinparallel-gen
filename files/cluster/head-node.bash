#!/bin/bash

# This Script Promotes a Worker-node to a Head-node
# - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ "$EUID" -ne 0 ]
then 
    echo "Please run as sudo head-node"
    exit 1
fi

# Setting static ip

echo "SETTING STATIC IP ADDRESS"
if ! grep "static ip_address=172.27.1.2/24" /etc/dhcpcd.conf > /dev/null
then
    # Inserting static IP after the string "metric 301"
    echo "ADDING STATIC IP"
    sed -i '/metric 301/a static ip_address=172.27.1.2\/24' /etc/dhcpcd.conf

    # Applying dhcpcd changes
    echo "APPLYING STATIC IP"
    dhcpcd --rebind eth1
else
    echo "Static IP has already been configured"
fi

# Confirm that dhcpcd has successfully set static IP before continuing
## Setting the static IP isn't instantaneous, so we need to make sure
##  it is set. If dhcpcd's duplicate address detection (DAD)
##  detects that the IP is already on the network,
##  it won't go through with setting the static IP.
## If the dhcp server was restarted while eth1 didn't have 
##  the static IP yet, it would complain about how there is no config
##  for the subnet that eth1 is currently in, but wouldn't fail
##  because the eth0 config was successful.
## The worker-node script does not have this check because the dhcp
##  server doesn't care about the eth1 interface anymore,
##  and because there can be multiple worker-nodes, unlike the requirement
##  for only one head-node
tries=0
until ip address show eth1 | grep "172.27.1.2/24" &> /dev/null
do
    let "tries++"
    echo -ne "\rStatic IP not set ($tries of 7 attempts attempted)"
    if [ $tries -gt 6 ]
    then
        echo -e "\nStatic IP not set after 30 seconds, reverting to worker node"
        echo "Are you connected to the cluster switch?"
        echo "Does the cluster you are connected to already have a head node?"
        # Removing head-node static IP
        sed -i 's+static ip_address=172.27.1.2/24++g' /etc/dhcpcd.conf

        # Removing the empty line left behind by prior command
        sed -i '/metric 301/,/static routers=172.27.1.1/{ /^[ \t]*$/d}' /etc/dhcpcd.conf

        # Applying dhcpcd changes
        dhcpcd --rebind eth1
        exit 1
    fi
    sleep 5
done
echo -e "\nStatic IP set"


# NFS Configuration

# Adding export of /hd-cluster to /etc/exports in case of reboot
echo "CONFIGURING NFS"
if ! grep "/hd-cluster 172.27.1.0/24(rw,sync,no_subtree_check)" /etc/exports
then
    echo "/hd-cluster 172.27.1.0/24(rw,sync,no_subtree_check)" >> /etc/exports
else
    echo "NFS has already been configured"
fi

# Starting export of /hd-cluster
## Exporting manually like this doesn't require a restart of the NFS server
##  and doesn't modify any other exports like running `exportfs -a` would.
## This command is equivalent to running `exportfs -a` with /etc/exports
##  only containing the line added above
echo "EXPORTING /hd-cluster"
exportfs -o rw,sync,no_subtree_check 172.27.1.0/24:/hd-cluster

# Configuring dhcp server 

if ! grep "BEGIN ETH1 BLOCK" /etc/dhcp/dhcpd.conf > /dev/null
then
    # Adding dhcp server configuration for eth1
    echo "CONFIGURING DHCP SERVER FOR ETH1"
    cat << EOF >> /etc/dhcp/dhcpd.conf 

# BEGIN ETH1 BLOCK
subnet 172.27.1.0 netmask 255.255.255.0 {
  range 172.27.1.3 172.27.1.254;
  option subnet-mask 255.255.255.0;
  option broadcast-address 172.27.1.255;
  option routers 172.27.1.2;
  option domain-name-servers 172.27.1.1;
  default-lease-time 30;
  max-lease-time 60;
}
# END ETH1 BLOCK

EOF

    # Adding interface eth1 to dhcp server
    echo "ADDING ETH1 INTERFACE"
    sed -i 's/INTERFACESv4="eth0"/INTERFACESv4="eth0 eth1"/g' /etc/default/isc-dhcp-server

    # Restarting dhcp server
    echo "RESTARTING DHCP SERVER" 
    systemctl restart isc-dhcp-server
else
    echo "DHCP server has already been configured"
fi

if [[ -n $DISPLAY ]]
then
    echo "ALLOWING CLUSTER TO USE DISPLAY"
    USER_HOME=$(getent passwd $SUDO_USER | cut -d ":" -f 6)
    cp $USER_HOME/.Xauthority /hd-cluster
else
    echo "No display found, skipping .Xauthority copy"
fi
