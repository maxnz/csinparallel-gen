#!/bin/bash
# Max Narvaez and Dick Brown

test "$USER" = hd-cluster || {
    echo "run as hd-cluster user only"
    exit
}

HOSTFILE=$HOME/hostfile
MCA_PARAMS_CONF=$HOME/.openmpi/mca-params.conf

rm -f $HOSTFILE
test -d $HOME/.openmpi || mkdir $HOME/.openmpi
rm -f $MCA_PARAMS_CONF

# Regex for a valid IP address
re_ip='[0-9]{1,3}(\.[0-9]{1,3}){3}'

# Parts of the command that aren't processed by this script 
#  and are passed to mpirun.openmpi command
REST=""

# Excluded nodes
EXCLUDE=""

# 0 - Do health check
# 1 - Skip health check, not hd-cluster user (UID 1100)
# 2 - Skip health check, manually disabled
HEALTHCHECK=$(test "$EUID" -eq 1100; echo $?)

while [ $# -gt 0 ]
do
    case "$1" in
        -X)
            shift
            if [ $# -gt 0 ]
            then
                EXCLUDE="$EXCLUDE $1"
                shift
            else
                echo "-X requires an argument"
                exit 1
            fi
            ;;
        -hc|--health-check)
            shift
            if [ $# -gt 0 ]
            then
                if [[ "${1,,}" == "no" ]]
                then
                    HEALTHCHECK=2
                elif [[ "${1,,}" == "yes" ]]
                then
                    HEALTHCHECK=0
                else
                    echo '--health-check requires a "yes" or "no" as its argument'
                    exit 1
                fi
                shift
            else
                echo "--health-check requires an argument"
                exit 1
            fi
            ;;
        -w|--xwindow)
            shift
            # From https://unix.stackexchange.com/a/62520 (-d isn't necessary)
            ENABLE_XWINDOWS=" -X -n"
            DISPLAY=${DISPLAY:-":0.0"}
            ;;
        *)
            REST="$REST $1"
            shift
            ;;
    esac
done

# The >&2 redirects to stderr without the bug associated with using > /dev/stderr
#  when logged into an account using su (https://stackoverflow.com/a/23550347/1944087)
#>&2 echo "Determining available nodes..."
echo "DETERMINING AVAILABLE NODES..."

# Determine what nodes are connected
## We use fping instead of ping because it can ping multiple targets.
## It also pings each target without waiting for a response from the last,
##  parallelizing the process and greatly increasing the speed.
##
## fping is told to ping each target only once (-c1), not print results
##  until the end (-q), and to ping all targets between 172.27.1.2 and
##  172.27.1.254 (-g 172.27.1.2 172.27.1.254)
##
## We then grep for the string "min/avg/max" which is only present when
##  the target was successfully reached.
## We then replace all spaces with underscores so that the for loop in the
##  next step doesn't separate the line into multiple parts.
LINES=$(fping -q -c1 -g 172.27.1.2 172.27.1.254 2>&1 | grep --color="never" "min/avg/max" | sed 's/ \+/_/g')

# Parse the output from fping and extract the IPs
## Because we added underscores, each line is separated by a space.
## We then loop through all the lines and extract the IP.
IPS=$(for line in $LINES; do echo $line | cut -d '_' -f 1; done)

# Exclude any nodes based on command line args
## If the node is available, exclude it and record that it was excluded.
## If it is not available, do nothing.
EXCLUDED=""
for IP in $EXCLUDE
do
    # Save the old list
    OLD=$IPS

    # Create the new list, only keeping IPs that don't match the excluded IP
    ## The -e and quotes in the echo command allow echo to print multiple lines,
    ##  which is needed for grep.
    if [[ "$IP" =~ $re_ip ]]
    then
        IPS=$(echo -e "$IPS" | grep -xv $(echo $IP | sed 's/\./\\\./g'))
    else
        IPS=$(echo -e "$IPS" | grep -v $(echo $IP | sed 's/\./\\\./g'))
    fi

    # If the list has changed, add the now-removed node to a list that will be
    #  printed later
    if [[ "$IPS" != "$OLD" ]]
    then
        EXCLUDED="$EXCLUDED $IP"
    fi
done

if [ -z "$IPS" ]
then
    echo "No nodes found, running as standalone computation"
    echo "Defaulting to loopback (127.0.0.1)"

    HOSTNAMES="127.0.0.1"
else
    # Tell the user what nodes are being used
    echo "Available nodes: $(echo $IPS)"

    # If any nodes were excluded, say that too
    if ! [ -z "$EXCLUDED" ]
    then
        echo "Excluded nodes: $EXCLUDED"
    fi

    # Convert the space-delimited list of IPs to a comma-delimited list
    HOSTNAMES=$(echo $IPS | sed 's/ /,/g')

    # Without the btl_tcp_if_include option, MPI tries to use eth0 and that 
    #  causes errors when running programs that utilize message passing
    #INTERFACES="--mca btl_tcp_if_include eth1"
    echo "btl_tcp_if_include = eth1" >> $MCA_PARAMS_CONF
fi

echo "CREATING hostfile"

for h in `echo $HOSTNAMES | tr , ' '`
do  echo $h slots=4 >> $HOSTFILE
done

# Check the health of the cluster before running the MPI job
if [ $HEALTHCHECK -eq 0 ]
then
    ERRORS=""
    echo "CHECKING CLUSTER HEALTH..."

    # Try to SSH into each node with passwordless ssh.
    # If it fails, add it to the list of nodes to warn the user about.
    ## The -o BatchMode=yes option tells it that this is a script and
    ##  that there is no user present to provide a password, so it
    ##  will not try to prompt for a password and will only use
    ##  publickey authentication
    for IP in $IPS
    do
        if ! ssh -o BatchMode=yes $IP exit &> /dev/null
        then
            ERRORS="$ERRORS $IP"
        fi
    done

    # If there were any nodes that did not allow passwordless SSH,
    #  alert the user and exit, otherwise tell the user the cluster
    #  is healthy
    if ! [ -z "$ERRORS" ]
    then
        echo "ERROR:  Passwordless SSH failed for the following nodes:$ERRORS"
        echo "Please restart or remove the nodes before running the command again, or ignore the nodes with the -X flag"
        echo "    e.g. \"mpirun $(for err in $ERRORS; do echo -n "-X $err "; done)${REST# }\""
        exit 1
    else
        echo "Cluster healthy"
    fi

# Print a warning if the check was manually disabled
elif [ $HEALTHCHECK -eq 2 ]
then
    echo "WARNING: Skipping check of cluster's health"
fi

echo "SETTING MPI JOB PARAMETERS"

echo "plm_rsh_agent = ssh$ENABLE_XWINDOWS" >> $MCA_PARAMS_CONF
echo "rmaps_base_mapping_policy = node" >> $MCA_PARAMS_CONF

echo "SETTING HOSTNAME FOR EACH NODE"

# set hostname for each pi
for h in `echo $HOSTNAMES | tr , ' '`
do  ssh-keygen -R $h | egrep -v "# Host $h found|$HOME/.ssh/known_hosts updated|Original contents retained as $HOME/.ssh/known_hosts.old"
    ssh $h /usr/HD/soc-hostname $h 
done
