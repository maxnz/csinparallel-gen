#!/bin/bash -e

# Create HD directory
install -m 777 -d "${ROOTFS_DIR}/usr/HD"
echo "Created HD Directory"

# Add version to HD directory
install -m 666 files/version "${ROOTFS_DIR}/usr/HD"

# Add hd-image.bash to HD directory
install -m 777 files/hd-image.bash "${ROOTFS_DIR}/usr/HD"

# Add PiTracker.bash to HD directory
install -m 777 files/PiTracker.bash "${ROOTFS_DIR}/usr/HD"
echo "Populated HD directory"

# Create a symbolic link so hd-image can be run without an explicit path
ln -s "${ROOTFS_DIR}/usr/HD/hd-image.bash" "${ROOTFS_DIR}/usr/bin/hd-image"
echo "Created hd-image symlink"

# Add PiTracker.service to systemd service files
install -m 644 files/PiTracker.service "${ROOTFS_DIR}/lib/systemd/system/PiTracker.service"
echo "Added PiTracker service"

# Reload systemd and enable PiTracker service
on_chroot << EOF
# systemctl daemon-reload
systemctl enable PiTracker.service
EOF

# Add hd-admin user
on_chroot << EOF
if ! id -u hd-admin >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" hd-admin
fi
echo "hd-admin:${ADMIN_PASS}" | chpasswd
adduser hd-admin sudo
EOF
