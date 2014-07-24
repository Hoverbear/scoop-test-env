#!/bin/sh
if [ ! -e /root/.ssh/id_rsa ]; then
  mkdir -p /root/.ssh
	ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)-$(date -I)" -f /root/.ssh/id_rsa -N ""
fi

exit 0
