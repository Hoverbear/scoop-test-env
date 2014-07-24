#!/bin/sh
REMOTE_ACCESS_PORT=13001
LOCAL_PORT_TO_FORWARD=3001

/usr/bin/autossh -M0 -p22 -N -R ${REMOTE_ACCESS_PORT}:localhost:${LOCAL_PORT_TO_FORWARD} autossh@hub -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o Protocol=2 -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no
