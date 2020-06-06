# HD Image Generation using `pi-gen`
This is a set of files that configure [`pi-gen`](https://github.com/RPi-Distro/pi-gen) to create a custom image for Hardware Design.

## General Overview
The image uses `ansible-pull` to automatically update itself using a StoGit [repository](https://stogit.cs.stolaf.edu/hd-image/hd-image) (see the repo for more details).

This modification to `pi-gen` sets up everything needed to enable the automatic `ansible-pull` updates, as well as automatic connection to St. Olaf Guest and adding the hd-admin user.

The image then takes care of updating itself from v3.0.0 to the latest version the next time it is booted.

## Requirements
- Raspberry Pi 3B/3B+/4B running Raspbian Buster
- USB flash drive with 64GB of space or more

## Usage
- Clone `pi-gen` and this repository
```bash
git clone https://github.com/RPi-Distro/pi-gen.git
git clone https://gitlab+deploy-token-15:798ax55zdqx4ABcBGWSk@stogit.cs.stolaf.edu/hd-image/hd-image-gen.git
```

- Install missing dependencies
```bash
sudo apt update
sudo apt install quilt qemu-user-static debootstrap zerofree zip bsdtar bc
```

- Copy modifications into `pi-gen`
```bash
cp -r hd-image-gen/pi-gen/* pi-gen/
```

- Add hd-admin password to config file (`pi-gen/config`)
```bash
ADMIN_PASS=""          # Put password on this line (in the quotes)
```

- Mount USB on `pi-gen/work`
```bash
cd pi-gen
sudo mount /dev/... work
# Replace the ... with the disk and partition you want to use,
# for example, sudo mount /dev/sdb1 work
```

- Run build script
```bash
sudo ./build.sh
```
*If there is an error saying that you're missing other dependencies, install those with apt like above*

- The image will take a while to build, somewhere in the neighborhood of a couple hours
- The working directory for the scripts is a subdirectory of work, named `$DATE-$IMG_NAME`
- The final image will be stored in `work/$WORK_DIR/export-image`
- If the `export-noobs` stage fails, don't worry because we only need the output from `export-image`

## More Detailed Overview

This repository modifies stages 2, 3 and 5 of `pi-gen`, as well as gives the config file needed.

##### Config

Multiple things happen in the config file:
- Variables are set
  - `IMAGE_NAME` - The name of the image, used to specify the output name (`hd-image-3.0.0`)
  - `TIMEZONE_DEFAULT` - Sets the timezone (`America/Chicago`)
  - `WPA_ESSID` - The SSID to connect to automatically (`St. Olaf Guest`)
  - `WPA_COUNTRY` - The country code for the country the Pi will be used in (`US`)
  - `ENABLE_SSH` - SSH is enabled when set to `1` (`1`)

- hd-admin account password is set
  - `export ADMIN_PASS` - The password for the hd-admin account is set here (see above)
    - Note the `export` - this is because the other variables are exported by the `build.sh` script, so for our own custom variables we have to export them ourselves
  - `if [ -z "$ADMIN_PASS" ] then; echo "ADMIN_PASS must be populated in config"; exit 1; fi`
    - This if statement checks that the `ADMIN_PASS` variable was set.
      This prevents the issue where you forgot to set the variable and the build runs for a long time, just to fail at the end of stage 4.

##### Stage 2

The file `SKIP_IMAGES` is added to the `stage2` directory, making that stage skip creating an image.
This image would be a lite version of the image, which is unnecessary for our purposes.

##### Stage 4

Stage 4 is where the customization happens:

- `00-packages`
  - Installs more packages for the image (i.e. `vim`, `emacs`, etc.)

- `01-run.sh`
  - The hd-admin account is added
  - The `/etx/xdg/autostart/piwiz.desktop` file is removed
    - This is what causes the "Welcome to Raspberry Pi" window to show up on startup (according to [this forum thread](https://www.raspberrypi.org/forums/viewtopic.php?t=231557))
    - Because we are already setting everything it would set as a part of our setup, we don't need it to show up
  - `ansible`, and thus `ansible-pull`, are installed
  - The files required for the `ansible-pull` functionality are added to the image
  - The PiTracker systemd service is created and enabled

  - *Notes*
    - The `on_chroot << EOF; EOF` idiom is equivalent to running the commands in it as root (i.e. with `sudo`)
      - `on_chroot` is a part of `pi-gen`, [located here](https://github.com/RPi-Distro/pi-gen/blob/master/scripts/common)
    - Make sure any `##-run.sh` files are executable, otherwise they won't run and there will be no indication as to why they didn't run

##### Stage 5

The files `SKIP` and `SKIP_IMAGES` are added to the `stage5` directory.
The `SKIP_IMAGES` file does the same thing it does in the `stage2` directory.
The `SKIP` file has the scripts skip stage 5 completely.
Stage 5 adds extra software to the image that students don't actually need (such as LibreOffice, etc.).
I also wasn't able to make the scripts work with stage 5 enabled.
