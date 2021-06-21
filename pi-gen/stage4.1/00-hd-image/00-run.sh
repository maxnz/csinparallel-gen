#!/bin/bash -e

on_chroot << EOF

cd /home/pi
wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.1.tar.gz
tar -zxf openmpi-4.1.1.tar.gz
cd openmpi-4.1.1
./configure --prefix=/usr/local --enable-mpi-java
sudo make all install
rm /home/pi openmpi-4.1.1.tar.gz
rm -rf /home/pi openmpi-4.1.1
EOF
echo -e "\e[2mInstalling openmpi...\e[22;32mdone\e[0m"
