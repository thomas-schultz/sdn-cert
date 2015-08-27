#!/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: script <ip> <port> {args = <in_port> <out_port>}"
	exit
fi
IP=$1
PORT=$2
shift; shift;

ovs-ofctl del-flows tcp:$IP:$PORT
ovs-ofctl del-meters tcp:$IP:$PORT -O OpenFlow13
ovs-ofctl del-groups tcp:$IP:$PORT -O OpenFlow11
ovs-ofctl add-flow tcp:$IP:$PORT "in_port=$1, actions=output:$2"