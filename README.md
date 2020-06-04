# HD Image Generation using `pi-gen`
This is a set of files that configure `pi-gen` to create a custom image for Hardware Design.

## General Overview
The image uses `ansible-pull` to automatically update itself using a StoGit
[repository](https://stogit.cs.stolaf.edu/hd-image/hd-image).
This sets up everything needed to enable the automatic `ansible-pull` updates.
The image then takes care of updating itself from v3.0.0 to the latest version
the next time it is booted.

## Requirements
- Raspberry Pi 3B/3B+/4B running Raspbian Buster
- USB flash drive with 64GB of space or more

## Usage
- Clone `pi-gen` and this repository
```
git clone https://github.com/RPi-Distro/pi-gen.git
git clone git@stogit.cs.stolaf.edu:hd-image/hd-image-gen.git
```

- Install missing dependencies
```
sudo apt install quilt qemu-user-static debootstrap zerofree zip bsdtar
```

- Copy modifications into `pi-gen`
```
cp -r hd-image-gen/pi-gen/* pi-gen/
```

- Add hd-admin password to config file (`pi-gen/config`)
```bash
ADMIN_PASS=          # Put password on this line
```

- Mount USB on `pi-gen/work`
```
cd pi-gen
sudo mount -o umask=000 /dev/disk/... work
```

- Run build script
```
sudo ./build.sh
```
