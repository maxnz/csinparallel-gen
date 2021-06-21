export TEXTDOMAIN=Linux-PAM

. gettext.sh

NAME=$(/bin/cat /etc/owner | /usr/bin/tr '[:upper:]' '[:lower:]')

if [ "$NAME" = "none" ]
then
    echo
    echo $(/usr/bin/gettext "/etc/owner still contains \"None\". Please update it by running")
    echo "$(/usr/bin/gettext "    hd-image change-owner username")"
    echo $(/usr/bin/gettext "(where username is your username)")
    echo
elif [ "$NAME" = "username" ]
then
    echo
    echo $(/usr/bin/gettext "/etc/owner contains \"username\". We don't believe this is a valid username.")
    echo $(/usr/bin/gettext "Please update it by running")
    echo "$(/usr/bin/gettext "    hd-image change-owner username")"
    echo $(/usr/bin/gettext "(where username is YOUR username)")
    echo
elif [ "$NAME" = "" ]
then
    echo
    echo $(/usr/bin/gettext "/etc/owner is empty. Please populate it by running")
    echo "$(/usr/bin/gettext "    hd-image change-owner username")"
    echo $(/usr/bin/gettext "(where username is your St. Olaf username)")
    echo
fi
