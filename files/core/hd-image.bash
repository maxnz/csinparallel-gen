#!/bin/bash

# hd-image: a tool for managing the HD Image
# Created by Max Narvaez

function show_help() {
    echo "Hardware Design Image Tool $(cat /usr/HD/version)"
    echo
    echo "Usage: hd-image [-h|-v|info|report|update|change-boot-user|"
    echo "                 change-owner|git-fsck|reset-wallpaper]"
    echo
    echo "Options:"
    echo "-h                show this help message"
    echo "-v                show the current version of the image"
    echo
    echo "info              show information about this Pi"
    echo "report [IP]       send info to PiTracker server, optionally specifying"
    echo "                    a specific IP to communicate with"
    echo "update            check for image updates"
    echo
    echo "change-boot-user  change which user's desktop the pi will boot to"
    echo "change-owner      change the contents of /etc/owner"
    echo
    echo "git-fsck          check all git repositories for errors"
    echo "reset-wallpaper   resets the wallpaper to default (temple.jpg)"
}

function show_update_help() {
    echo "Hardware Design Image Tool $(cat /usr/HD/version)"
    echo
    echo "hd-image update"
    echo
    echo "Usage: hd-image update [-h] [--branch BRANCH]" 
    echo "                       [--version-override VERSION]"
    echo "Options:"
    echo "-h                Show this help message"
    echo "-b BRANCH, --branch BRANCH"
    echo "                  Set the branch to update from"
    echo "-v VERSION, --version-override VERSION"
    echo "                  Override the version number"
}

function missing_argument() {
    echo "Missing argument for $1"
    exit 1
}

function git_fsck() {
    GITDIRS=$(sudo find /home -name .git 2> /dev/null)
    for d in $GITDIRS
    do
        cd $d/..
        if ! /usr/bin/git fsck &> /dev/null
        then
            echo $(pwd)
        fi
        cd - > /dev/null
    done
}


## Information Functions ##

# Check the git health of the Pi
function get_git_health() {
    GIT_ERRS=$(git_fsck)
    if [ -z "$GIT_ERRS" ]
    then
        echo "Good"
    else
        echo "Errors Found: $(echo $GIT_ERRS)"
    fi
}

# Get the IP for a specific interface
function get_ip() {
    if [ $# -ne 1 ]
    then
        return 1
    else
        ip address show $1 | grep "inet " | sed 's/  \+/ /g' | cut -d ' ' -f 3 | cut -d '/' -f 1
    fi
}

# Get the MAC address for a specific interface
function get_mac() {
    if [ $# -ne 1 ]
    then
        return 1
    else
        ip address show $1 | grep "link/ether" | sed 's/  \+/ /g' | cut -d ' ' -f 3
    fi
}

# Get the owner of the Pi as specified by /etc/owner
function get_owner() {
    cat /etc/owner
}

# Get the Pi revision
function get_pi_rev() {
    cat /proc/cpuinfo | grep Revision | cut -d ' ' -f 2
}

# Get the Pi's serial number
function get_pi_serial() {
    cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2
}

# Get the SD Card's serial number
function get_sd_serial() {
    cat /sys/block/mmcblk0/device/cid
}


## Commands ##

function info() {
    echo "Image Version:        $(cat /usr/HD/version)"
    echo "Hardware Revision:    $(get_pi_rev)"
    echo "Pi Serial Number:     $(get_pi_serial)"
    echo "SD Serial Number:     $(get_sd_serial)"
    echo "WiFi IP:              $(get_ip wlan0)"
    echo "WiFi MAC:             $(get_mac wlan0)"
    echo "Ethernet IP:          $(get_ip eth0)"
    echo "Ethernet MAC:         $(get_mac eth0)"
    echo "Owner:                $(get_owner)"
}

function report() {
    # IP address of the PiTracker server
    SERVERIP=${1:-"pitracker.cs.stolaf.edu"}

    # Test connection to PiTracker server
    tries=0
    until ping -c 1 -W 2 $SERVERIP &> /dev/null
    do
        if [ $tries -gt 10 ]
        then
            >&2 echo "Could not connect to PiTracker server"
            exit 1
        fi
        sleep 10
        let "tries++"
    done

    echo "Found PiTracker at $SERVERIP"

    PIMSG="{\"serialNumber\": \"$(get_pi_serial)\", \
            \"imageVersion\": \"$(cat /usr/HD/version)\", \
            \"wlan0IpAddress\": \"$(get_ip wlan0)\", \
            \"wirelessMacAddress\": \"$(get_mac wlan0)\", \
            \"eth0IpAddress\": \"$(get_ip eth0)\", \
            \"ethernetMacAddress\": \"$(get_mac eth0)\", \
            \"sdSerialNumber\": \"$(get_sd_serial)\", \
            \"hardwareVersion\": \"$(get_pi_rev)\", \
            \"gitHealth\": \"$(get_git_health)\", \
            \"owner\": \"$(get_owner)\"}"

    SDMSG="{\"serialNumber\": \"$(get_sd_serial)\", \
            \"piSerialNumber\": \"$(get_pi_serial)\", \
            \"imageVersion\": \"$(cat /usr/HD/version)\", \
            \"owner\": \"$(get_owner)\"}"

    if [ -z $(get_pi_serial) ]
    then
        >&2 echo "No serial number found"
        echo $PIMSG
        echo $SDMSG
        exit 2
    fi

    # Send data to PiTracker server

    echo "Communicating with PiTracker at $SERVERIP"

    # Pi Table
    curl -i -X POST -H "Content-Type: application/json" $SERVERIP/pis -d "${PIMSG//[$'\t\r\n']}"
    echo

    # SD Table
    curl -i -X POST -H "Content-Type: application/json" $SERVERIP/sDs -d "${SDMSG//[$'\t\r\n']}"
    echo
}

function update() {
    # Test for connection to StoGit
    tries=0
    until ping -c 1 -W 2 stogit.cs.stolaf.edu &> /dev/null
    do
        if [ $tries -gt 10 ]
        then
            echo "Could not connect to StoGit"
            exit 1
        fi
        sleep 10
        let "tries++"
    done

    # Confirm integrity of git repo
    LASTDIR=$(pwd)
    if cd ~/.ansible/pull/raspberrypi 2> /dev/null
    then
        if ! /usr/bin/git fsck &> /dev/null
        then
            cd ..
            echo "Corrupt ansible-pull git directory detected - removing"
            rm -rf raspberrypi
        fi
        cd $LASTDIR
    fi

    # Check if passwordless sudo is enabled
    if ! sudo -n echo a &> /dev/null
    then
        ASKSUDO="--ask-become-pass"
        echo "You will be prompted for a BECOME pass - this is the password you use with sudo"
        echo
    else
        ASKSUDO=""
    fi

    /usr/local/bin/ansible-pull \
    --url https://gitlab+deploy-token-12:sErpRQP96JzfVponpBh-@stogit.cs.stolaf.edu/hd-image/hd-image.git \
    --extra-vars imgVersion=${IMAGEVER:-$(cat /usr/HD/version)} --checkout ${BRANCH:-master} $ASKSUDO

    report
}

function change_boot_user() {
    if [ "$EUID" -ne 0 ]
    then
        echo "Please run as sudo hd-image change-boot-user"
        return
    fi

    USER="$1"

    # Check that a username is specified, otherwise ask until provided one
    while [ -z $USER ]
    do
        echo -n "Enter your username: "
        read USER
    done

    # Check that user has a home directory
    ## Otherwise the desktop will not load and the user select screen will be shown
    if [[ -d /home/$USER ]]
    then
        # Taken from raspi-config's do_boot_behaviour method (https://github.com/RPi-Distro/raspi-config/blob/master/raspi-config)
        systemctl set-default graphical.target
        ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
        cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF
        sed /etc/lightdm/lightdm.conf -i -e "s/^\(#\|\)autologin-user=.*/autologin-user=$USER/"
        echo "SUCCESS: Will boot to $USER's desktop on next boot"
    else
        echo -e "\e[31mERROR: Specified user does not have a home directory\e[0m"
    fi
}

function change_owner() {
    USERNAME="$1"

    # Check that a proper username is specified, otherwise ask until provided one
    while /bin/true
    do
        if [ -z $USERNAME ]
        then
            echo -n "Enter your username: "
            read USERNAME
        elif [[ "${USERNAME,,}" == "none" ]]
        then
            echo "Nice try, but that's not a username"
            echo -n "Enter your username: "
            read USERNAME
        elif [[ "${USERNAME,,}" == "username" ]]
        then
            echo "Nice try, but we want your username, not the literal string 'username'"
            echo -n "Enter your username: "
            read USERNAME
        elif [[ "${USERNAME,,}" == "pi" ]]
        then
            echo "We would like your St. Olaf username or some other identifying string, not 'pi'"
            echo -n "Enter your username: "
            read USERNAME
        else
            break
        fi
    done

    echo $USERNAME > /etc/owner

    echo "Owner has been set to $USERNAME"
}

if [ $# -eq 0 ]
then
    show_help
    exit 1
fi    

case "$1" in
    -h|help|--help)
        show_help
        exit 0
        ;;
    -v|version|--version)
        shift
        echo "HD Image Version $(cat /usr/HD/version)"
        echo "Developed by Max Narvaez '21, Tanaka Khondowe '22, George Kokalas '22"
        echo
        exit 0
        ;;
    update)
        shift
        while [ $# -gt 0 ]
        do
            case "$1" in
                -h|help)
                    show_update_help
                    ;;
                -b|--branch)
                    shift
                    if [ $# -gt 0 ]
                    then
                        BRANCH=$1
                        shift
                    else
                        missing_argument "-b"
                    fi
                    ;;
                -v|--version-override)
                    shift
                    if [ $# -gt 0 ]
                    then
                        IMAGEVER=$1
                        shift
                    else
                        missing_argument "-v"
                    fi
                    ;;
                *)
                    show_update_help
                    exit 1
                    ;;
            esac
        done
        update
        exit 0
        ;;
    info)
        shift
        info
        exit 0
        ;;
    report)
        shift
        report $@
        exit 0
        ;;
    git-fsck)
        shift
        get_git_health
        exit 0
        ;;
    reset-wallpaper)
        shift
        export DISPLAY=:0.0
        pcmanfm --set-wallpaper /usr/share/rpd-wallpaper/temple.jpg
        exit 0
        ;;
    change-boot-user)
        shift
        change_boot_user $1
        exit 0
        ;;
    change-owner)
        shift
        change_owner $1
        exit 0
        ;;
    *)
        show_help
        exit 1
        ;;
esac
