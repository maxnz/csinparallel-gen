# HD-Image: The Official Hardware Design Raspberry Pi Image

This repository is used to create/update the HD Image. 
The image will check for updates at specified times.
Therefore, you will always have the latest version provided your Pi can contact StoGit.


## Supported Hardware Revisions

The HD Image is designed to work on the Raspberry Pi 4B - 2GB version.

The image has been tested on the following revisions:
- Raspberry Pi 4B - 1GB
- Raspberry Pi 4B - 2GB
- Raspberry Pi 4B - 4GB
- Raspberry Pi 4B - 8GB
- Raspberry Pi 3B
- Raspberry Pi 3B+

The image has been tested on the Raspberry Pi Zero W, with partial success.
The lack of an `eth0` interface messes up the DHCP server.
Otherwise, no other issues were noticed.

## Image Tools

### PiTracker

The HD Image includes a program called PiTracker which is used to report information about the Pi to a server (located in the server room running on two Raspberry Pis and accessible at `pitracker.cs.stolaf.edu`).

The information it reports includes:
- Pi's Serial Number
- Pi's Hardware Revision
- Pi's WiFi IP Address
- Pi's WiFi MAC Address
- SD Card's Serial Number
- Image Version
- Owner of the Pi (taken from /etc/owner)

Note that this tracking only works when the Pi is connected to a St. Olaf network, such as St. Olaf Guest.

### hd-image

The HD Image also includes a tool called `hd-image` that can help you manage your image.
It can help you
- Check what version your image is
- Manually check for an image update
- Manually send a report to PiTracker
- View information about your Pi
- Change the "owner" of the pi
- Change what user the pi desktop boots to

Run `hd-image -h` to see information about how to use the tool.

## How it Works

The image uses `ansible-pull` to check for updates. This is the inverse of how ansible is typically used.
This is done because running an ansible playbook from a central computer at a specified time may not update all Pis because they might not all be turned on at the time.
This also requires an account on the image that can be used for running ansible.
Instead, the HD Image automatically checks for updates at two times: boot and 5am.
This way, the Pis will always be updated each time it is booted, but if the Pi is left on for multiple days at a time, it will still receive updates.
The update check at boot time is done with a systemd service that runs on startup.
The 5am daily check is done with a cron job.

Whenever the Pi checks for an update, it downloads the repository and looks for a file called `local.yml`.
It then runs any plays in that file.
Our `local.yml` file contains one play with one task which finds all `.yaml` files in `updates/` and includes their tasks if the version number they are associated with is greater than the version reported by the Pi.
It then runs these plays in order by version number.
After every update check, a report is sent to the PiTracker server.


## Creating Your Own Copy of the Image

There are two options for creating your own version of the image: `ansible-pull` and `pi-gen`.

### Image Generation using `ansible-pull`

This method works similar to how the pi gets its updates.

To start, install a fresh copy of Raspbian Buster on your Pi.
Perform basic setup and make sure the Pi has an internet connection and can reach StoGit.

Then run the commands
```
sudo pip3 install ansible

ansible-pull -U https://gitlab+deploy-token-12:sErpRQP96JzfVponpBh-@stogit.cs.stolaf.edu/hd/hd-tas/hd-image/hd-image.git -e imgVersion=0
```
This will install the latest version of the HD Image on your Pi and set it up to check for updates automatically.


### Image Generation using `pi-gen`

This method uses the official [`pi-gen`](https://github.com/RPi-Distro/pi-gen) scripts that are used by the Raspberry Pi Foundation to create the official Raspberry Pi OS image.
We modify them slightly to customize them for Hardware Design.

#### Requirements
- Raspberry Pi 3B/3B+/4B running Raspbian Buster
- USB flash drive with 64GB of space or more
  - The USB should have a Linux filesystem, such as ext4
  - If you need to image it to the correct filesystem, run `sudo mkfs.ext4 /dev/...`, replacing the `...` with the correct disk partition (i.e. `/dev/sda1`)
    - Make sure the partition is not mounted anywhere (`sudo mount -l`)
    - When prompted, enter `y` to confirm you want to overwrite the filesystem


#### Usage
- Clone `pi-gen` and this repository
```bash
git clone https://github.com/RPi-Distro/pi-gen.git
git clone https://gitlab+deploy-token-12:sErpRQP96JzfVponpBh-@stogit.cs.stolaf.edu/hd/hd-tas/hd-image/hd-image.git hd-image-gen
```

- Install missing dependencies
```bash
sudo apt update
sudo apt install coreutils quilt parted qemu-user-static debootstrap zerofree zip \
dosfstools bsdtar libcap2-bin grep rsync xz-utils file git curl bc \
qemu-utils kpartx
```

- Copy modifications into `pi-gen`
```bash
cp -r hd-image-gen/pi-gen/* pi-gen/
```

- Add hd-admin password to a new file called `pi-gen/admin_pass`
```bash
export ADMIN_PASS=""          # Put password in the quotes
```
  - The config file will check for this and throw an error if it is done incorrectly, saving you from going through all the stages before it runs into an issue

- Mount USB on `pi-gen/work`
```bash
cd pi-gen
mkdir work
sudo mount /dev/... work
# Replace the ... with the disk and partition you want to use,
# for example, sudo mount /dev/sda1 work
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

We modify stages 2, 4 and 5 of `pi-gen`, create a new stage 4.1, and give a config file.

#### Config

Multiple things happen in the config file:

- Variables are set
  - `IMAGE_NAME` - The name of the image, used to specify the output name (`hd-image-3.1.3`)
  - `TIMEZONE_DEFAULT` - Sets the timezone (`America/Chicago`)
  - `LOCALE_DEFAULT` - Sets the default locale (`en_US.UTF-8`)
  - `WPA_ESSID` - The SSID to connect to automatically (`St. Olaf Guest`)
  - `WPA_COUNTRY` - The country code for the country the Pi will be used in (`US`)
  - `ENABLE_SSH` - SSH is enabled when set to `1` (`1`)

- hd-admin account password is set
  - `source admin_pass` - Gets a file that will export the password for the hd-admin account:
    - `export ADMIN_PASS` - The password for the hd-admin account is set here
      - Note the `export` - this is because the other variables are exported by the `build.sh` script, so for our own custom variables we have to export them ourselves
    - There are a couple if statement checks that confirm that the `ADMIN_PASS` variable was set.
      This prevents the issue where you forgot to set the variable and the build runs for a long time, just to fail at the end of stage 4.1

- `ANSIBLE_BRANCH` is set and exported
  - This variable controls what branch the `ansible-pull` command will use to perform the updates.
    This is helpful for testing changes without modifying the master branch

##### Stage 2

The file `SKIP_IMAGES` is added to the `stage2` directory, making that stage skip creating an image.
This image would be a lite version of the image, which is unnecessary for our purposes.

##### Stage 4

The file `SKIP_IMAGES` is added to the `stage2` directory, making that stage skip creating an image.
This image would be a lite version of the image, which is unnecessary for our purposes.

##### Stage 4.1

Stage 4. is where our customization happens:

- `00-packages`
  - Installs more packages for the image (i.e. `vim`, `emacs`, etc.)

- `00-run.sh`
  - hd-admin account is added
  - Screen resolution is set (otherwise VNC doesn't work properly)
  - `/etx/xdg/autostart/piwiz.desktop` file is removed
    - This is what causes the "Welcome to Raspberry Pi" window to show up on startup (according to [this forum thread](https://www.raspberrypi.org/forums/viewtopic.php?t=231557))
    - Because we are already setting everything it would set as a part of our setup, we don't need it to show up
  - `ansible`, and thus `ansible-pull`, are installed
  - Keyboard locale is set

- `01-run.sh`
  - `ansible-pull` is run to perform all of our updates

###### *Notes*
  - The `on_chroot << EOF; EOF` idiom is equivalent to running the commands in it as root (i.e. with `sudo`)
    - `on_chroot` is a part of `pi-gen`, [located here](https://github.com/RPi-Distro/pi-gen/blob/master/scripts/common)
  - Make sure any `##-run.sh` files are executable, otherwise they won't run and there will be no indication as to why they didn't run

##### Stage 5

The files `SKIP` and `SKIP_IMAGES` are added to the `stage5` directory.
The `SKIP_IMAGES` file does the same thing it does in the `stage2` directory.
The `SKIP` file has the scripts skip stage 5 completely.
Stage 5 adds extra software to the image that students don't actually need (such as LibreOffice, etc.).

## Creating an Update

See [UPDATE.md](https://stogit.cs.stolaf.edu/hd/hd-tas/hd-image/hd-image/blob/master/UPDATE.md) for instructions.
