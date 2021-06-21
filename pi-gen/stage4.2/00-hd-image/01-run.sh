#!/bin/bash -e

#### Run ansible-pull to perform updates

echo "Running ansible-pull..."
on_chroot << EOF
/usr/local/bin/ansible-pull \
    --url https://gitlab+deploy-token-12:sErpRQP96JzfVponpBh-@stogit.cs.stolaf.edu/hd-image/hd-image.git \
    --extra-vars imgVersion="3.0.0" --checkout "$ANSIBLE_BRANCH"
EOF
echo -e "\e[2mRunning ansible-pull...\e[22;32mdone\e[0m"
