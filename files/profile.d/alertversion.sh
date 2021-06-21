export TEXTDOMAIN=Linux-PAM

. gettext.sh

echo
echo "$(/usr/bin/gettext "HD Image Version v")$(/bin/cat /usr/HD/version)"

if [ -e /usr/HD/.updated ]
then 
    /usr/games/cowsay $(/usr/bin/gettext "Your HD Image has been updated")
    /bin/rm /usr/HD/.updated
fi
