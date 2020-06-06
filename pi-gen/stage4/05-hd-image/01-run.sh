#!/bin/bash -e


# Add hd-image user

on_chroot << EOF
if ! id -u hd-admin >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" hd-admin
fi
echo "hd-admin:${ADMIN_PASS}" | chpasswd
adduser hd-admin sudo
EOF

echo "Added hd-image user"


# Prevent Welcome to Raspberry Pi window from appearing

rm "${ROOTFS_DIR}/etc/xdg/autostart/piwiz.desktop"
echo "Removed piwiz.desktop file"


# Install Ansible

on_chroot << EOF
pip3 install ansible
EOF


# HD Files

install -m 777 -d "${ROOTFS_DIR}/usr/HD"
echo "Created HD Directory"

install -m 666 files/version "${ROOTFS_DIR}/usr/HD"
install -m 777 files/hd-image.bash "${ROOTFS_DIR}/usr/HD"
install -m 777 files/PiTracker.bash "${ROOTFS_DIR}/usr/HD"
echo "Populated HD directory"

if [ -f "${ROOTFS_DIR}/usr/bin/hd-image" ]
then
     rm "${ROOTFS_DIR}/usr/bin/hd-image"
fi

ln -s "/usr/HD/hd-image.bash" "${ROOTFS_DIR}/usr/bin/hd-image"
echo "Created hd-image symlink"

install -m 644 files/PiTracker.service "${ROOTFS_DIR}/lib/systemd/system/PiTracker.service"
echo "Added PiTracker service"

on_chroot << EOF
systemctl enable PiTracker.service
EOF
echo "Enabled PiTracker to run at startup"

