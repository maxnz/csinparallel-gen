#!/bin/bash
chpasswd <<EOF
pi:$2
$1:$2
EOF
