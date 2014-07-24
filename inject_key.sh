#!/bin/bash
# First parameter is the endpoint number.

PUBKEY=$(sudo nsenter --target $(docker inspect --format {{.State.Pid}} endpoint-$1) --mount --uts --ipc --net --pid cat /root/.ssh/id_rsa.pub)
sudo nsenter --target $(docker inspect --format {{.State.Pid}} hub) --mount --uts --ipc --net --pid /bin/bash <<EOF
	mkdir -p /home/autossh/.ssh; echo -e $PUBKEY >> /home/autossh/.ssh/authorized_keys
EOF
# TODO: More professional.
PUBKEY="Your mom"
