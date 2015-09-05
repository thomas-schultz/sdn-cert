#!/bin/bash

REPO="https://github.com/emmericp/MoonGen"

if [ $# -lt 2 ]; then
	echo "Usage: script <ip> <working_dir> [folder [iface_names]]"
	exit
fi
IP=$1
WD=$2
FILE="setup_MoonGen.sh"
shift
shift
if [ $# -lt 1 ]; then
	FOLDER=""
else
	FOLDER=$1
fi
shift
scp $FOLDER$FILE root@$IP:$WD
ssh root@$IP "cd $WD; ./$FILE $WD $REPO $@;"
