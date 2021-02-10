#!/bin/sh

set -e

MAKEOPTS="-j$(( $(getconf _NPROCESSORS_ONLN) + 1 ))"

if [ $# -lt 1 ]; then
	echo "Usage: $(basename $0) arch BUILD_NAME BUILD_NUMBER SOURCEDIR [build|modules]"
	exit 1
fi

ARCH=$1
BUILD_NAME=$2
BUILD_NUMBER=$3
SOURCEDIR=$4
ACTION=$5

# hacks before Gbuildbot has all args
if [ "$2" = 'modules' ];then
	ACTION='modules'
fi
if [ -z "$ACTION" ];then
	ACTION=build
fi

build() {
	FDIR="$(dirname $(realpath $0))/linux-$ARCH-build/"

	echo "DEBUG: $ACTION for $ARCH to $FDIR"
	MAKEOPTS="$MAKEOPTS O=$FDIR"

	case $ACTION in
	build)
		echo "DO: mrproper"
		make $MAKEOPTS mrproper

		echo "DO: generate config from defconfig"
		make $MAKEOPTS defconfig

		echo "DO: build"
		make $MAKEOPTS
	;;
	modules)
		make $MAKEOPTS modules
	;;
	*)
		echo "ERROR: unknow action: $ACTION"
		exit 1
	;;
	esac
}

build
