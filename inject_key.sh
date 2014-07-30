#!/bin/bash
# First parameter is the endpoint number.

ENDPOINT_NUMBER=$1

PUBKEY=$(sudo nsenter --target $(docker inspect --format {{.State.Pid}} endpoint-$ENDPOINT_NUMBER) --mount --uts --ipc --net --pid cat /root/.ssh/id_rsa.pub)
sudo nsenter --target $(docker inspect --format {{.State.Pid}} endpoint-$ENDPOINT_NUMBER) --mount --uts --ipc --net --pid /bin/bash <<EOF
	sed -i -e "s/REMOTE_ACCESS_PORT=13001/REMOTE_ACCESS_PORT=`expr 13000 + $ENDPOINT_NUMBER`/" /etc/service/endpoint_tunnel/run
EOF
sudo nsenter --target $(docker inspect --format {{.State.Pid}} hub) --mount --uts --ipc --net --pid /bin/bash <<EOF
	mkdir -p /home/autossh/.ssh
	echo -e $PUBKEY >> /home/autossh/.ssh/authorized_keys
EOF
# TODO: More professional.
PUBKEY="Your mom"
