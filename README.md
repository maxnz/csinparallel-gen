# HD Image Generation using `pi-gen`
This is a set of files that configure `pi-gen` to create a custom image for Hardware Design.

## General Overview
The image uses `ansible-pull` to automatically update itself using a StoGit [repository](https://stogit.cs.stolaf.edu/hd-image/hd-image) (see the repo for more details).

This modification to `pi-gen` sets up everything needed to enable the automatic `ansible-pull` updates, as well as automatic connection to St. Olaf Guest and adding the hd-admin user.

The image then takes care of updating itself from v3.0.0 to the latest version the next time it is booted.

## Requirements
- Raspberry Pi 3B/3B+/4B running Raspbian Buster
- USB flash drive with 64GB of space or more

## Usage
- Clone `pi-gen` and this repository
```
git clone https://github.com/RPi-Distro/pi-gen.git
git clone https://gitlab+deploy-token-15:798ax55zdqx4ABcBGWSk@stogit.cs.stolaf.edu/hd-image/hd-image-gen.git
```

- Install missing dependencies
```
sudo apt update
sudo apt install quilt qemu-user-static debootstrap zerofree zip bsdtar bc
```

- Copy modifications into `pi-gen`
```
cp -r hd-image-gen/pi-gen/* pi-gen/
```

- Add hd-admin password to config file (`pi-gen/config`)
```bash
ADMIN_PASS=""          # Put password on this line (in the quotes)
```

- Mount USB on `pi-gen/work`
```
cd pi-gen
sudo mount /dev/disk/... work    # Figure out which disk and partition you want and use that to replace the ...
```

- Run build script
```
sudo ./build.sh
```
*If there is an error saying that you're missing other dependencies, install those with apt like above*

## More Detailed Overview

This repository modifies stages 2, 3 and 5 of `pi-gen`, as well as gives the config file needed.

##### Config

In the config file:
- The image name is specified (`hd-image-3.0.0`)
- The default locale is specified (`America/Chicago`)
- The default SSID to connect to (`St. Olaf Guest`)
- Enables SSH
- Has a line where the hd-admin password should be added (see above).

##### Stage 2

The file `SKIP_IMAGES` is added to the `stage2` directory, making that stage skip creating an image.
This image would be a lite version of the image, which is unnecessary and would be no different than the official lite image.

##### Stage 4

Stage 4 is where the customization happens:

- `00-packages`
  - Installs required packages for the image

- `01-run.sh`
  - The files required for the `ansible-pull` functionality are added to the image
  - The PiTracker systemd service is created and enabled
  - The hd-admin account is added

##### Stage 5

The files `SKIP` and `SKIP_IMAGES` are added to the `stage5` directory.
The `SKIP_IMAGES` file does the same thing it does in the `stage2` directory.
The `SKIP` file has the scripts skip stage 5 completely.
Stage 5 adds extra software to the image that students don't actually need (such as LibreOffice, etc.).
I also wasn't able to make the scripts work with stage 5 enabled.

