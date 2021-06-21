# Changelog

## [3.0.8](updates/3.0.8.yaml)

3.0.8 fixes `hd-image change-boot-user` and modifies the dhcpcd service to restart on failure.

## [3.0.4](updates/3.0.4.yaml)

3.0.4 adds files and configurations for creating Pi clusters.
- Add a custom ssh key for the cluster
  - Only allow key to authorize connections from the 172.27.1.* subnet
  - Automatically use the key instead of the default when connecting to the 172.27.1.* subnet
- Add `timehost.stolaf.edu` to ntp config
- Add `head-node.bash`
  - Script for converting a worker to a head
- Add `worker-node.bash`
  - Script for converting a head back to a worker
- Update version to 3.0.4


## [3.0.3](updates/3.0.3.yaml)

3.0.3 modifies files and adds the CSinParallel directory.
- Add the CSinParallel directory to /etc/skel and /home/pi
- Add a line to all `.bashrc` files that shows a message when the image has been updated
- Add checks to `.bashrc` for `/etc/owner` containing "None" or "username"
- Update version to 3.0.3


## [3.0.2](updates/3.0.2.yaml)

3.0.2 sets up the networking interfaces.
- Configure eth0
  - Set metric to 302
  - Set static IP to 172.27.0.254
  - Set router to 172.27.0.1
  - Set dns to 172.27.0.1
- Configure eth1
  - Set metric to 301
  - Set router to 172.27.1.1
  - Set dns to 172.27.1.1
- Configure wlan0
  - Set metric to 202 (preferring it over the others)
- Configure isc-dhcp-server
  - Add eth0 to interfaces used by the server
  - Add configuration for 172.27.0.* subnet
  - Add custom configuration for /etc/systemd/system/isc-dhcp-server.service
  - Enable isc-dhcp-server
- Update version to 3.0.2


## [3.0.1](updates/3.0.1.yaml)

3.0.1 adds our custom programs to the image and sets up automatic updating.
- Add `/usr/HD/` directory
  - Add `PiTracker.bash`
  - Add `hd-image.bash`
  - Create symlink from `/usr/bin/hd-image` to `/usr/HD/hd-image.bash`
- Create `/etc/owner`
- Create Updater service
  - Runs at boot to check for updates and report info to PiTracker server
- Create Updater cron job
  - Runs at 5 AM daily to check for updates and report info to PiTracker server
- Update version to 3.0.1


## [3.0.0](updates/3.0.0.yaml)

*It is assumed that the user has configured locale, timezone and WiFi and has enabled SSH and VNC*

- Upgrade packages
- Install packages
  - isc-dhcp-server
  - vim
  - emacs
  - cowsay
  - sl
- Update version to 3.0.0

---

**All updates from version 2 have been consolidated into 3.0.0 - 3.0.2.**  
(version 2 files have been moved into `files/.old` and `updates/.old`)


## [2.0.7](updates/.old/2.0.7.yaml)

- Change permissions of `/usr/HD` so all users can remove `.updated`
- Update version to 2.0.7


## [2.0.6](updates/.old/2.0.6.yaml)

- Remove `sudo` from `rm /usr/HD/.updated` command in `.bashrc`
- Update version to 2.0.6


## [2.0.5](updates/.old/2.0.5.yaml)

- Add checks to `.bashrc` for `/etc/owner` containing "None" or "username"
- Update version to 2.0.5


## [2.0.4](updates/.old/2.0.4.yaml)

- Update `PiTracker.bash` to use new PiTracker subdomain
- Update version to 2.0.4


## [2.0.3](updates/.old/2.0.3.yaml)

- Update `hd-image.bash`
- Update `PiTracker.bash`
- Modify systemd service and cron job to work with new `hd-image.bash`
- Update version to 2.0.3


## [2.0.2](updates/.old/2.0.2.yaml)

- Add a line to all `.bashrc` files that shows a message when the image has been updated
- Enable and start isc-dhcp-server (wasn't enabled properly in 2.0.0)
- Update `hd-image.bash`
- Update version to 2.0.2


## [2.0.1](updates/.old/2.0.1.yaml)

- Create `/etc/owner`
- Update `hd-image.bash`
- Update version to 2.0.1


## [2.0.0](updates/.old/2.0.0.yaml)

- Upgrade packages
- Install packages
  - isc-dhcp-server
  - vim
  - emacs
  - cowsay
  - sl
- Set static IP to 10.0.0.254
- Configure isc-dhcp-server
  - Add eth0 to interfaces used by the server
  - Modify `/etc/dhcp/dhcpd.conf`
  - Modify service to restart on failure
    - Copy `/run/systemd/generator.late/isc-dhcp-server.service` to `/etc/systemd/system/`
    - Modify `/etc/systemd/system/isc-dhcp-server.service`
- Add `/usr/HD/` directory
  - Add `PiTracker.bash`
  - Add `hd-image.bash`
  - Create symlink from `/usr/bin/hd-image` to `/usr/HD/hd-image.bash`
- Add CSinParallel directory to `/etc/skel/` and `/home/pi/`
- Create cron job for PiTracker
  - Runs at 5 am every day to check for updates and report info to PiTracker server
- Create PiTracker service
  - Runs at boot to check for updates and report info to PiTracker server
- Update version to 2.0.0


## 1.0.0

Old image (Not located here)
