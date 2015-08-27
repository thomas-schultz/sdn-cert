#!/bin/bash


# TODO select linux distribution to install deps
#apt-get install gcc make cmake linux-headers-$(uname -r)
#zypper in gcc make kernel-devel

if [ $# -lt 1 ]; then
	REPO="https://github.com/emmericp/MoonGen"
else
	REPO=$1
fi
shift
for IFACE in "$@"
do
    ip a flush dev $IFACE 
done

git clone $REPO
cd MoonGen
git pull
git submodule update --init
./build.sh
./setup-hugetlbfs.sh
ln -sf build/MoonGen moongen