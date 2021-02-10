#!/bin/sh

set -e

MAKEOPTS="-j$(( $(getconf _NPROCESSORS_ONLN) + 1 ))"

if [ $# -lt 1 ]; then
	echo "Usage: $(basename $0) arch"
	exit 1
fi

ARCH=$1

case "$ARCH" in
	"amd64")
		;;
	"arm")
		MAKEOPTS="ARCH=arm CROSS_COMPILE=armv7a-hardfloat-linux-gnueabi- $MAKEOPTS"
		;;
	*)
		echo "Unsupported arch: $ARCH"
		exit 1
		;;
esac

FDIR="$(dirname $(realpath $0))/linux-$ARCH-build/"

echo "DEBUG: output is in $FDIR"

MAKEOPTS="$MAKEOPTS O=$FDIR"

shift

make $MAKEOPTS $*
