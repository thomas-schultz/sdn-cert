#!/bin/bash

IFACE1="eth1"
IFACE2="eth2"
OVS_PORT=6633

/etc/init.d/openvswitch-switch restart
ovs-vsctl set-controller br0 ptcp:$OVS_PORT
ip l set $IFACE1 up
ip l set $IFACE2 up