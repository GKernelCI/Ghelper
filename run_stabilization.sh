#!/bin/bash
set -x

# check the artifact directory of a build for generating LAVA jobs
# LAVA lifecycle (Generating, submit, check) is done by run_tests.py

ARCH=$1 # amd64
# make cannot handle ":" in a path, so we need to replace it
BUILDER_NAME=$2 # gentoo_sources
TOOLCHAIN_TODO="gcc"
if [ -z "$TOOLCHAIN_TODO" ];then
	echo "ERROR: I do not find the toolchain to use"
	exit 1
else
	echo "DEBUG: build use toolchain $TOOLCHAIN_TODO"
fi
BUILD_NUMBER=$3 # 16
DISCOVERY_TIME=$4
FILESERVER=/var/www/fileserver/
LAVA_SERVER=140.211.166.173:10080
STORAGE_SERVER=140.211.166.171:8080
SCRIPT_DIR=$(cd "$(dirname "$0")"|| exit;pwd)

usage() {
	echo "Usage: $0 ARCH BUILDER_NAME BUILD_NUMBER"
}

if [ -z "$ARCH" ] ;then
	usage
	exit 1
fi

if [ -z "$BUILDER_NAME" ] ;then
	usage
	exit 1
fi

if [ -z "$BUILD_NUMBER" ] ;then
	usage
	exit 1
fi

# permit to override default
if [ -e config.ini ];then
	echo "INFO: Loading default from config.ini"
	. config.ini
fi

SCANDIR="$FILESERVER/sys-kernel/$BUILDER_NAME/$ARCH/$BUILD_NUMBER/"
if [ ! -e "$SCANDIR" ];then
	echo "ERROR: $SCANDIR does not exists"
	exit 1
fi

echo "CHECK $SCANDIR"
for defconfig in $(ls $SCANDIR)
do
	echo "CHECK: $defconfig"
	echo "BOOT: $SCANDIR/$defconfig/$TOOLCHAIN_TODO"
	./deploy.py --arch $ARCH \
		--buildname $BUILDER_NAME \
		--buildnumber $BUILD_NUMBER \
		--toolchain $TOOLCHAIN_TODO \
		--defconfig $defconfig \
		--fileserver $FILESERVER \
		--fileserverfqdn http://$STORAGE_SERVER/ \
		--waitforjobsend
	if [ $? -ne 0 ];then
		echo "ERROR: there is some fail"
		exit 1
	fi
done

exit 0
