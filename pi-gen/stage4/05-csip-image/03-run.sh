#!/bin/bash -e

#### Equivalent to ansible-pull for v3.0.2 (https://github.com/babatana/csinparallel-image/blob/master/updates/3.0.2.yaml)

# Add CSinParallel directory

wget http://csinparallel.cs.stolaf.edu/CSinParallel.tar.gz
tar -xf CSinParallel.tar.gz -C "${ROOTFS_DIR}/etc/skel"
echo "Add CSinParallel directory"

tar -xf CSinParallel.tar.gz -C "${ROOTFS_DIR}/home/pi"
on_chroot << EOF
chown -R pi:pi "/home/pi/CSinParallel"
EOF
echo "Add CSinParallel directory to pi user"


# Add update check to the bashrc files

cat << EOF >> "${ROOTFS_DIR}/home/pi/.bashrc"
if [ -e /usr/CSiP/.updated ]
then 
    cowsay CSiP Image has been updated to v\$(cat /usr/CSiP/version)
    rm /usr/CSiP/.updated
fi
EOF

cat << EOF >> "${ROOTFS_DIR}/etc/skel/.bashrc"
if [ -e /usr/CSiP/.updated ]
then 
    cowsay CSiP Image has been updated to v\$(cat /usr/CSiP/version)
    rm /usr/CSiP/.updated
fi
EOF
echo "Add update check to the bashrc files" 
