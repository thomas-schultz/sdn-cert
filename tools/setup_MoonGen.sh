#!/bin/bash


# TODO select linux distribution to install deps
#apt-get install gcc make cmake linux-headers-$(uname -r)
#zypper in gcc make kernel-devel

if [ $# -eq 0 ]; then
	WD="/tmp"
	REPO="https://github.com/emmericp/MoonGen"
fi
if [ $# -ge 1 ]; then
	WD=$1
fi
if [ $# -ge 2 ]; then
	REPO=$2
fi
shift
shift
for IFACE in "$@"
do
    ip a flush dev $IFACE 
done

cd $WD
git clone $REPO
cd MoonGen
git pull
git submodule update --init
./build.sh
./setup-hugetlbfs.sh
ln -sf build/MoonGen moongen
