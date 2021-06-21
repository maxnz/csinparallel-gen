#!/bin/bash

# Regex for a valid IP address
re_ip='[0-9]{1,3}(\.[0-9]{1,3}){3}'

test "$USER" = hd-cluster || {
    echo "Please run as sudo head-node"
    exit 1
}

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
## We use stderr instead of stdout so that any output from the mpirun command can be
##  redirected into a file without the extra messages from this script.
## Essentially, make it so that the output into a file will be the exact same as if
##  mpirun was used without this script.
>&2 echo "Determining available nodes..."

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
    >&2 echo "No nodes found, running as standalone computation"
    >&2 echo "Defaulting to loopback (127.0.0.1)"

    HOSTNAMES="127.0.0.1"
else
    # Tell the user what nodes are being used
    >&2 echo "Available nodes: $(echo $IPS)"

    # If any nodes were excluded, say that too
    if ! [ -z "$EXCLUDED" ]
    then
        >&2 echo "Excluded nodes: $EXCLUDED"
    fi

    # Convert the space-delimited list of IPs to a comma-delimited list
    HOSTNAMES=$(echo $IPS | sed 's/ /,/g')

    # Without the btl_tcp_if_include option, MPI tries to use eth0 and that 
    #  causes errors when running programs that utilize message passing
    INTERFACES="--mca btl_tcp_if_include eth1"
fi

# Repeat the hosts 4 times so each core can be used
HOSTNAMES="$HOSTNAMES,$HOSTNAMES,$HOSTNAMES,$HOSTNAMES"

# Check the health of the cluster before running the MPI job
if [ $HEALTHCHECK -eq 0 ]
then
    ERRORS=""
    >&2 echo "Checking cluster health..."

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
        >&2 echo "Passwordless SSH failed for the following nodes:$ERRORS"
        >&2 echo "Please restart or remove the nodes before running the command again, or ignore the nodes with the -X flag"
        >&2 echo "    e.g. \"mpirun $(for err in $ERRORS; do echo -n "-X $err "; done)${REST# }\""
        exit 1
    else
        >&2 echo "Cluster healthy"
    fi

# Print a warning if the check was manually disabled
elif [ $HEALTHCHECK -eq 2 ]
then
    >&2 echo "WARNING: Skipping check of cluster's health"
fi

>&2 echo "Sending command to mpirun"

# Add an empty line between our output above and the MPI output below
>&2 echo

# Run the MPI job, inserting an argument specifying what hosts are available
## The map-by node option tells it to assign processes to nodes in a round-robin fashion.
##
## We use mpirun.openmpi because that is a later item in the symbolic link chain
##  that starts with mpirun:
##  (/usr/bin/mpirun -> /etc/alternatives/mpirun -> /usr/bin/mpirun.openmpi -> /usr/bin/orterun)
## We replaced the /usr/bin/mpirun symbolic link with a link to this script.
/usr/bin/mpirun.openmpi -H $HOSTNAMES $INTERFACES --mca pls_rsh_agent "ssh$ENABLE_XWINDOWS" --mca --map-by node $REST
