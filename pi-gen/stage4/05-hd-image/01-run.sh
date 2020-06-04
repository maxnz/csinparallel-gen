#!/bin/bash -e

install -m 777 -d "${ROOTFS_DIR}/usr/HD"
install -m 777 files/hd-image.bash "${ROOTFS_DIR}/usr/HD/"
install -m 777 files/PiTracker.bash "${ROOTFS_DIR}/usr/HD"
ln -s "${ROOTFS_DIR}/usr/bin/hd-image.bash" "${ROOTFS_DIR}/usr/HD/hd-image"      # Looking back on this, this may not be correct, might need the .bash on the second part instead of the first.
install -m 644 files/PiTracker.service "${ROOTFS_DIR}/lib/systemd/system/PiTracker.service"
install -m 666 files/version "${ROOTFS_DIR}/usr/HD"

on_chroot << EOF
systemctl daemon-reload
systemctl enable PiTracker.service
EOF

on_chroot << EOF
if ! id -u hd-admin >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" hd-admin
fi
echo "hd-admin:${ADMIN_PASS}" | chpasswd
adduser hd-admin sudo
EOF
