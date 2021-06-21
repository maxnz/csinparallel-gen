#!/bin/bash -e

# Add hd-admin user

echo -n "Confirming that \$ADMIN_PASS is populated..."
if [ -z "$ADMIN_PASS" ]
then
    echo -e "\e[31merror\e[0m"
    echo "ADMIN_PASS must be populated in admin_pass"
    echo "File should contain 'export ADMIN_PASS=\"\"' with the password in the quotes"
    exit 1
else
    echo -e "\e[32mconfirmed\e[0m"
fi

echo "Adding hd-admin user..."
on_chroot << EOF
if ! id -u hd-admin >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" hd-admin
fi
echo "hd-admin:${ADMIN_PASS}" | chpasswd
adduser hd-admin sudo
EOF
echo -e "\e[2mAdding hd-admin user...\e[22;32mdone\e[0m"


# Enable VNC Server

echo "Enabling VNC Server..."
on_chroot << EOF
systemctl enable vncserver-x11-serviced.service
EOF
echo -e "\e[2mEnabling VNC Server...\e[22;32mdone\e[0m"


# Set Resolution to DMT Mode 82 1920x1080 60Hz 16:9

echo -n "Setting HDMI Config to DMT Mode 82 1920x1080 60Hz 16:9..."
sed -i 's/#hdmi_force_hotplug=1/hdmi_force_hotplug=1/g' "${ROOTFS_DIR}/boot/config.txt"
sed -i 's/#hdmi_group=1/hdmi_group=2/g' "${ROOTFS_DIR}/boot/config.txt"
sed -i 's/#hdmi_mode=1/hdmi_mode=82/g' "${ROOTFS_DIR}/boot/config.txt"
echo -e "\e[32mdone\e[0m"


# Prevent Welcome to Raspberry Pi window from appearing

echo -n "Removing piwiz.desktop file..."
rm -f "${ROOTFS_DIR}/etc/xdg/autostart/piwiz.desktop"
echo -e "\e[32mdone\e[0m"


# Install Ansible

echo "Installing ansible..."
on_chroot << EOF
pip3 install ansible
EOF
echo -e "\e[2mInstalling ansible...\e[22;32mdone\e[0m"


# Install mpi4py

echo "Installing mpi4py..."
on_chroot << EOF
pip3 install mpi4py
EOF
echo -e "\e[2mInstalling mpi4py...\e[22;32mdone\e[0m"


# Install matplotlib

echo "Installing matplotlib..."
on_chroot << EOF
pip3 install matplotlib
EOF
echo -e "\e[2mInstalling matplotlib...\e[22;32mdone\e[0m"


# Install numpy

echo "Installing numpy..."
on_chroot << EOF
pip3 install numpy
EOF
echo -e "\e[2mInstalling numpy...\e[22;32mdone\e[0m"


# Set Keyboard Locale

echo -n "Setting keyboard locale..."
on_chroot << EOF
echo "XKBMODEL=pc105\nXKBLAYOUT=us\nXKBVARIANT=\nXKBOPTIONS=\nBACKSPACE=guess" > /etc/default/keyboard
EOF
echo -e "\e[32mdone\e[0m"
