#!/bin/sh

set -e

MAKEOPTS="-j$(( $(getconf _NPROCESSORS_ONLN) + 1 ))"

if [ $# -lt 1 ]; then
	echo "Usage: $(basename $0) arch BUILD_NAME BUILD_NUMBER SOURCEDIR"
	exit 1
fi

ARCH=$1
BUILD_NAME=$2
BUILD_NUMBER=$3
SOURCEDIR=$4

build() {
	FDIR="$(dirname $(realpath $0))/linux-$ARCH-build/"

	echo "DEBUG: output is in $FDIR"
	MAKEOPTS="$MAKEOPTS O=$FDIR"

	case $BUILD_NAME in
	*)
		make $MAKEOPTS
	;;
	modules)
		make $MAKEOPTS modules
	;;
	esac
}

build
