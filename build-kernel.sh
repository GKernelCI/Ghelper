#!/bin/sh

set -e

MAKEOPTS="-j$(( $(getconf _NPROCESSORS_ONLN) + 1 ))"

if [ $# -lt 1 ]; then
	echo "Usage: $(basename $0) arch BUILD_NAME BUILD_NUMBER SOURCEDIR"
	exit 1
fi

# arch must be a gentoo arch keyword
ARCH=$1
BUILD_NAME=$2
BUILD_NUMBER=$3
SOURCEDIR=$4

# permit to override default
if [ -e config.ini ];then
	echo "INFO: Loading default from config.ini"
	. ./config.ini
fi

case "$ARCH" in
	"amd64")
		;;
	"arm")
		MAKEOPTS="ARCH=arm CROSS_COMPILE=armv7a-hardfloat-linux-gnueabi- $MAKEOPTS"
		;;
	*)
		echo "Unsupported arch: $1"
		exit 1
		;;
esac

FDIR="$(dirname $(realpath $0))/linux-$1-build/$BUILD_NAME/$BUILD_NUMBER/defconfig/"

echo "DEBUG: output is in $FDIR"

MAKEOPTS="$MAKEOPTS O=$FDIR"

shift

make $MAKEOPTS $*

