#!/bin/bash

ARCH=$1
# make cannot handle ":" in a path, so we need to replace it
BUILDER_NAME=$(echo $2 | sed 's,:,_,g')
BUILD_NUMBER=$3
FILESERVER=/var/www/fileserver/

copy_artifact() {
	local defconfig="$1"
	local toolchain="$2"

	FDIR="linux-$ARCH-build/$BUILDER_NAME/$BUILD_NUMBER/$defconfig/$toolchain"

	IMAGE_PATH="$FDIR/arch/x86/boot/bzImage"
	COPY_IMAGE_PATH="${FILESERVER}"/"${BUILDER_NAME}"/"${BUILD_NUMBER}"/
	echo "DEBUG: copy artifacts from $FDIR to $COPY_IMAGE_PATH"
	mkdir -p "${COPY_IMAGE_PATH}"
	chmod -R 755 "${COPY_IMAGE_PATH}"

	cp -rf "${IMAGE_PATH}" "${COPY_IMAGE_PATH}"
	chmod 755 "${COPY_IMAGE_PATH}"/*
}

BCONFIG="$(dirname $(realpath $0))/build-config/"
if [ ! -e "$BCONFIG/$ARCH" ];then
	echo "ERROR: $ARCH is unsupported"
	exit 1
fi

for defconfigdir in $(ls $BCONFIG/$ARCH)
do
	echo "INFO: $ARCH $defconfigdir"
	BCDIR=$BCONFIG/$ARCH/$defconfigdir
	if [ -e $BCDIR/defconfig ];then
		defconfig="$(cat $BCDIR/defconfig)"
	else
		echo "ERROR: no defconfig in $BCDIR, defaulting to defconfig"
		defconfig="defconfig"
	fi
	copy_artifact $defconfig gcc
done
