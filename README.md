# HD Image pi-gen
This is a set of files that configure pi-gen to create a custom image for Hardware Design.


## Requirements
- Raspberry Pi 3B/3B+/4B running Raspbian Buster
- USB flash drive with 64GB of space or more


## Usage
- Clone pi-gen and this repository
```
git clone https://github.com/RPi-Distro/pi-gen.git
git clone git@stogit.cs.stolaf.edu:hd-image/pi-gen-hd-image.git
```

- Install missing dependencies
```
sudo apt install quilt qemu-user-static debootstrap zerofree zip bsdtar
```

- Copy modifications into `pi-gen`
```
cp -r pi-gen-hd-image/pi-gen/* pi-gen/
```

- Add hd-admin password to config file
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
