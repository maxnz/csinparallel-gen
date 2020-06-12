#!/bin/bash -e

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

on_chroot << EOF
systemctl enable Updater.service
EOF
echo "Enabled Updater to run at startup on first run"


# Set Keyboard Locale

on_chroot << EOF
echo "XKBMODEL=pc105\nXKBLAYOUT=us\nXKBVARIANT=\nXKBOPTIONS=\nBACKSPACE=guess" > /etc/default/keyboard
EOF


# Temporary workaround for https://github.com/RPi-Distro/pi-gen/issues/414 until it's updated

echo 0 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-3f300000.mmcnr:wlan"
echo 0 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-fe300000.mmcnr:wlan"

