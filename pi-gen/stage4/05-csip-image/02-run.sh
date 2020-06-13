#!/bin/bash -e

#### Equivalent to ansible-pull for v3.0.1 (https://github.com/babatana/csinparallel-image/blob/master/updates/3.0.1.yaml)

cat << EOF
interface eth0
metric 302
static ip_address=10.0.0.254
static routers=10.0.0.1
static domain_name_servers=10.0.0.1
nolink

interface wlan0
metric 202
EOF
