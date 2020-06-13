#!/bin/bash -e

#### Equivalent to ansible-pull for v3.0.1 (https://github.com/babatana/csinparallel-image/blob/master/updates/3.0.1.yaml)

cat << EOF >> "${ROOTFS_DIR}/etc/dhcpcd.conf"
interface eth0
metric 302
static ip_address=10.0.0.254
static routers=10.0.0.1
static domain_name_servers=10.0.0.1
nolink

interface wlan0
metric 202
EOF

echo  Set static IP 

#Add eth0 to DHCP server
sed -e 's/INTERFACESv4=""/INTERFACESv4="eth0"/g' -f "${ROOTFS_DIR}/etc/default/isc-dhcp-server" 
echo "Add eth0 to DHCP server"

#Configure DHCP server Part 1
sed -e 's/option domain-name \"example.org\";//g' -f "${ROOTFS_DIR}/etc/dhcp/dhcpd.conf"
echo "Configure DHCP server Part 1"

#Configure DHCP server Part 2
sed -e 's/option domain-name-servers ns1.example.org, ns2.example.org;//g' -f "${ROOTFS_DIR}/etc/dhcp/dhcpd.conf"
echo "Configure DHCP server Part 2"

#Configure DHCP server Part 3
cat << EOF >> "${ROOTFS_DIR}/etc/dhcp/dhcpd.conf"
default-lease-time 600;
max-lease-time 7200;
option subnet-mask 255.255.255.0;
option broadcast-address 10.0.0.255;
option routers 10.0.0.254;
option domain-name-servers 10.0.0.1;

subnet 10.0.0.0 netmask 255.255.255.0 {
range 10.0.0.2 10.0.0.253;
}
EOF
echo "Configure DHCP server Part 3"

#Configure DHCP server service
install -m 644 files/isc-dhcp-server.service "${ROOTFS_DIR}/etc/systemd/system/isc-dhcp-server.service"
echo "Configure DHCP server service"

#Enable dhcp server
on_chroot << EOF
systemctl enable isc-dhcp-server
EOF
echo "Enable dhcp server"