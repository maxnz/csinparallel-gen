# CSinParallel Image Generation using `pi-gen`
This is a set of files that configure [`pi-gen`](https://github.com/RPi-Distro/pi-gen) to create a custom image for CSinParallel.

## General Overview
The image uses `ansible-pull` to automatically update itself using a [GitHub repository](https://github.com/babatana/csinparallel-image) (see the repo for more details).
*(After the first update, it will disable auto-updates, though they can be turned on again and will then stay on).*

This modification to `pi-gen` sets up everything needed to enable updating via `ansible-pull`.

## Requirements
- Raspberry Pi 3B/3B+/4B running Raspbian Buster
- USB flash drive with 64GB of space or more
  - The USB should have a Linux filesystem, such as ext4
  - If you need to image it to the correct filesystem, run `sudo mkfs.ext4 /dev/...`, replacing the `...` with the correct disk partition (i.e. `/dev/sda1`)
    - Make sure the partition is not mounted anywhere
    - When prompted, enter `y` to confirm you want to overwrite the filesystem


## Usage
- Clone `pi-gen` and this repository
```bash
git clone https://github.com/RPi-Distro/pi-gen.git
git clone https:/github.com/maxnz/csinparallel-gen.git
```

- Install missing dependencies
```bash
sudo apt update
sudo apt install quilt qemu-user-static debootstrap zerofree zip bsdtar bc
```

- Copy modifications into `pi-gen`
```bash
cp -r csinparallel-gen/pi-gen/* pi-gen/
```

- Mount USB on `pi-gen/work`
```bash
cd pi-gen
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

This repository modifies stages 2, 4 and 5 of `pi-gen`, as well as gives the config file needed.

#### Config

Some variables are set in the config:
- `IMAGE_NAME` - The name of the image, used to specify the output name (`csip-image-3.0.0`)
- `ENABLE_SSH` - SSH is enabled when set to `1` (`1`)

#### Stage 2

The file `SKIP_IMAGES` is added to the `stage2` directory, making that stage skip creating an image.
This image would be a lite version of the image, which is unnecessary for our purposes.

#### Stage 4

Stage 4 is where the customization happens:

- `00-packages`
  - Installs more packages for the image (i.e. `vim`, `emacs`, etc.)

- `01-run.sh`
  - `ansible`, and thus `ansible-pull`, are installed
  - The files required for the `ansible-pull` functionality are added to the image

###### *Notes*
  - The `on_chroot << EOF; EOF` idiom is equivalent to running the commands in it as root (i.e. with `sudo`)
    - `on_chroot` is a part of `pi-gen`, [located here](https://github.com/RPi-Distro/pi-gen/blob/master/scripts/common)
  - Make sure any `##-run.sh` files are executable, otherwise they won't run and there will be no indication as to why they didn't run

#### Stage 5

The files `SKIP` and `SKIP_IMAGES` are added to the `stage5` directory.
The `SKIP_IMAGES` file does the same thing it does in the `stage2` directory.
The `SKIP` file has the scripts skip stage 5 completely.
Stage 5 adds extra software to the image that we don't actually need (such as LibreOffice, etc.).
