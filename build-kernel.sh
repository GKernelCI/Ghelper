#!/bin/sh

set -e

MAKEOPTS="-j$(( $(getconf _NPROCESSORS_ONLN) + 1 ))"

if [ $# -lt 1 ]; then
	echo "Usage: $(basename $0) arch"
	exit 1
fi

ARCH=$1

FDIR="$(dirname $(realpath $0))/linux-$ARCH-build/"

echo "DEBUG: output is in $FDIR"

MAKEOPTS="$MAKEOPTS O=$FDIR"

case $2 in
*)
make $MAKEOPTS
;;
modules)
make $MAKEOPTS modules
;;
esac
