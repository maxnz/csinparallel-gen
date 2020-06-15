#!/bin/bash -e

#### Equivalent to ansible-pull for v3.0.0 (https://github.com/babatana/csinparallel-image/blob/master/updates/3.0.0.yaml)

# Enable VNC Server

on_chroot << EOF
systemctl enable vncserver-x11-serviced.service
EOF
echo "Enabled VNC server"

#Set Resolution to DMT Mode 82 1920x1080 60Hz 16:9
sed -i 's/#hdmi_force_hotplug=1/hdmi_force_hotplug=1/g' "${ROOTFS_DIR}/boot/config.txt"
sed -i 's/#hdmi_group=1/hdmi_group=2/g' "${ROOTFS_DIR}/boot/config.txt"
sed -i 's/#hdmi_mode=1/hdmi_mode=82/g' "${ROOTFS_DIR}/boot/config.txt"
echo "Set Resolution to DMT Mode 82 1920x1080 60Hz 16:9"

# Install Ansible

on_chroot << EOF
pip3 install ansible
EOF


# CSiP Files

install -m 777 -d "${ROOTFS_DIR}/usr/CSiP"
echo "Created CSiP Directory"

install -m 666 files/version "${ROOTFS_DIR}/usr/CSiP"
install -m 777 files/csip-image.bash "${ROOTFS_DIR}/usr/CSiP"
echo "Populated CSiP directory"

ln -f -s "/usr/CSiP/csip-image.bash" "${ROOTFS_DIR}/usr/bin/csip-image"
echo "Created csip-image symlink"

install -m 644 files/Updater.service "${ROOTFS_DIR}/lib/systemd/system/Updater.service"
echo "Added Updater service"


# Set Keyboard Locale

on_chroot << EOF
echo "XKBMODEL=pc105\nXKBLAYOUT=us\nXKBVARIANT=\nXKBOPTIONS=\nBACKSPACE=guess" > /etc/default/keyboard
EOF


# Temporary workaround for https://github.com/RPi-Distro/pi-gen/issues/414 until it's updated

echo 0 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-3f300000.mmcnr:wlan"
echo 0 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-fe300000.mmcnr:wlan"
