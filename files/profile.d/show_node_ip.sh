export TEXTDOMAIN=Linux-PAM

. gettext.sh

# show Pi's IP address on eth1 interface
if  /usr/sbin/ip address show eth1 &> /dev/null
then
    echo "$(/usr/bin/gettext "This node's IP address on the cluster is ")$(/usr/sbin/ip address show eth1 | /usr/bin/grep "inet " | /usr/bin/sed 's/ \+/ /g' | /usr/bin/cut -d ' ' -f 3 | /usr/bin/cut -d '/' -f 1)"
fi
