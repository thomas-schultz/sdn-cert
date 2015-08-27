#!/bin/bash

if [ $# -eq 3 ]; then
	LOOP_COUNT=0
elif [ $# -eq 6 ]; then
	BASE_IP=$4
	LOOP_COUNT=$5
	OUT_PORT=$6	
else
	echo "Usage: (run)     script <ip> <port> <numIP>"
	echo "       (prepare) script <ip> <port> <numIP> <baseIP> <loops> <out_port>"
	exit
fi

IP=$1;
PORT=$2
NUM_IP=$3
FLOW_FILE="/tmp/flows_"
shift; shift; shift;

function run() {
	if [ $LOOP_COUNT -eq 0 ]; then
		setFlows
	else
		createFlows
	fi
}

function setFlows() {
	ovs-ofctl del-flows tcp:$IP:$PORT
	ovs-ofctl del-meters tcp:$IP:$PORT -O OpenFlow13
	ovs-ofctl del-groups tcp:$IP:$PORT -O OpenFlow11

	ovs-ofctl add-flows tcp:$IP:$PORT $FLOW_FILE$NUM_IP
	ovs-ofctl add-flow tcp:$IP:$PORT "dl_type=0x0842, actions=controller"
}

function createFlows() {
	start=$(($(date +%s%N)/1000000))
	CURRENT_IP=$BASE_IP
	LOOP=1
	n=1
	echo -n > $FLOW_FILE$NUM_IP
	while [ $LOOP -le $LOOP_COUNT ]; do
		echo "generating file with $NUM_IP flows"
		MOD_IP=$CURRENT_IP
		FILE=$FLOW_FILE$NUM_IP
		for i in $(seq $n $NUM_IP); do
			incIP
			echo "ip, nw_dst=$CURRENT_IP, actions=mod_nw_dst=$MOD_IP,output:$OUT_PORT" >> $FILE
		done
		n=$(( $NUM_IP + 1 ))
		NUM_IP=$(( NUM_IP * 2 ))
		LOOP=$(( $LOOP + 1 ))
		if [ $LOOP -le $LOOP_COUNT ]; then
			cat $FILE > $FLOW_FILE$NUM_IP
		fi		
	done
	end=$(($(date +%s%N)/1000000))
	echo "task finished in $(($end - $start)) ms"
}

function incIP() {
	local A=$(echo $CURRENT_IP | cut -d. -f1)
	local B=$(echo $CURRENT_IP | cut -d. -f2)
	local C=$(echo $CURRENT_IP | cut -d. -f3)
	local D=$(echo $CURRENT_IP | cut -d. -f4)
	
	D=$(( $D + 1 ))
	if [ "$D" -gt 255 ]; then
		D=0
		C=$(($C + 1))
	fi
	if [ "$C" -gt 255 ]; then
		C=0
		B=$(($B + 1))
	fi
	if [ "$B" -gt 255 ]; then
		B=0
		A=$(($A + 1))
	fi
	if [ "$A" -gt 255 ]; then
		A=0
	fi
	CURRENT_IP=$A.$B.$C.$D
}

run
exit


