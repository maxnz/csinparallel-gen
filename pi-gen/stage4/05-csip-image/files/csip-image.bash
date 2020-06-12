#!/bin/bash

# csinparallel-image: a tool for managing the CSinParallel Image
# Created by Max Narvaez

IMAGEVER=`cat /usr/CSiP/version`
BRANCH=

show_help() {
    echo "CSinParallel Image Tool $IMAGEVER"
    echo
    echo "A tool for managing your CSinParallel image"
    echo
    echo "Usage: csip-image [-h|-v|info|update|git-fsck|reset-wallpaper]"
    echo "Options:"
    echo "-h                show this help message"
    echo "-v                show the current version of the image"
    echo
    echo "info              show information about this Pi"
    echo "update            check for image updates"
    echo
    echo "git-fsck          check all git repositories for errors"
    echo "reset-wallpaper   resets the wallpaper to default (temple.jpg)"
    exit 0
}

show_update_help() {
    echo "CSinParallel Image Tool $IMAGEVER"
    echo
    echo "csip-image update"
    echo
    echo "Usage: csip-image update [-h|-b BRANCH|-v VERSION]"
    echo "Options:"
    echo "-h            show this help message"
    echo "-b BRANCH     set the branch to update from"
    echo "-v VERSION    override the version number"
    exit 0
}

missing_argument() {
    echo "Missing argument for $1"
    exit 1
}

info() {
    SERIAL=`cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2`
    IPv4=`ifconfig wlan0 | grep "inet " | sed 's/  \+/ /g' | cut -d ' ' -f 3`
    MAC=`ifconfig wlan0 | grep ether | sed 's/  \+/ /g' | cut -d ' ' -f 3`
    SDSERIAL=`cat /sys/block/mmcblk0/device/cid`
    HARDREV=`cat /proc/cpuinfo | grep Revision | cut -d ' ' -f 2`

    echo "Image Version:        $IMAGEVER"
    echo "Hardware Revision:    $HARDREV"
    echo "Pi Serial Number:     $SERIAL"
    echo "SD Serial Number:     $SDSERIAL"
    echo "WiFi IP:              $IPv4"
    echo "WiFi MAC:             $MAC"
}

git_fsck() {
    GITDIRS=`find /home -name .git 2> /dev/null`
    GITCHK=0
    for d in $GITDIRS
    do
        cd $d/..
        echo $d
        if ! /usr/bin/git fsck
        then
            GITCHK=1
        fi
        echo
    done
}

update() {
    # Test for internet connection
    tries=0
    while ! ping -c 1 -W 2 8.8.8.8 &> /dev/null
    do
        if [ $tries -gt 3 ]
        then
            /usr/bin/logger -t csip-image "Could not connect to internet"
            exit 1
        fi
        sleep 10
        let "tries++"
    done

    /usr/local/bin/ansible-pull \
    -U https://github.com/babatana/csinparallel-image.git \
    -e imgVersion=$IMAGEVER -C ${BRANCH:-master}
}

if test $# -eq 0
then
    show_help
fi    

while test $# -gt 0
do
    case "$1" in
        -h|help)
            show_help
            ;;
        -v|version)
            shift
            echo "Image version is: $IMAGEVER"
            echo
            exit 0
            ;;
        update)
            shift
            while test $# -gt 0
            do
                case "$1" in
                    -h|help)
                        show_update_help
                        ;;
                    -b)
                        shift
                        if test $# -gt 0
                        then
                            BRANCH=$1
                            shift
                        else
                            missing_argument "-b"
                        fi
                        ;;
                    -v)
                        shift
                        if test $# -gt 0
                        then
                            IMAGEVER=$1
                            shift
                        else
                            missing_argument "-v"
                        fi
                        ;;
                    *)
                        show_update_help
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
        git-fsck)
            shift
            git_fsck
            exit $GITCHK
            ;;
        reset-wallpaper)
            shift
            export DISPLAY=:0.0
            pcmanfm --set-wallpaper /usr/share/rpd-wallpaper/temple.jpg
            exit 0
            ;;
        *)
            show_help
            ;;
    esac
    exit 0
done

