#!/bin/bash

ARCH=$1
# make cannot handle ":" in a path, so we need to replace it
BUILDER_NAME=$(echo $2 | sed 's,:,_,g')
BUILD_NUMBER=$3
FILESERVER=/var/www/fileserver/

copy_artifact() {
	local defconfig="$1"
	local toolchain="$2"
	local b_dir="$3"

	FDIR="linux-$ARCH-build/$BUILDER_NAME/$BUILD_NUMBER/$defconfig/$toolchain"

	COPY_IMAGE_PATH="${FILESERVER}/${BUILDER_NAME}/$ARCH/${BUILD_NUMBER}/$defconfig/$toolchain/"
	echo "DEBUG: copy artifacts from $FDIR to $COPY_IMAGE_PATH"

	mkdir -p "${COPY_IMAGE_PATH}"
	for fartifact in $(ls $b_dir/artifacts)
	do
		echo "DEBUG: handle artifact $fartifact"
		while read artifact
		do
			echo "INFO: copy $artifact from $FDIR to $COPY_IMAGE_PATH"
			cp -a --dereference $FDIR/$artifact $COPY_IMAGE_PATH/
		done < "$b_dir/artifacts/$fartifact"
	done

	echo "COPY: config"
	cp "$FDIR/.config" "${COPY_IMAGE_PATH}/config"
	echo "COPY: build.log"
	cp "$FDIR/build.log" "${COPY_IMAGE_PATH}/build.log.txt"
	if [ -e "$FDIR/nomodule" ];then
		echo "No modules to copy"
	else
		echo "COPY modules.tar.gz"
		cp -v $FDIR/modules.tar.gz "${COPY_IMAGE_PATH}/"
	fi
	chmod --recursive o+rX "${COPY_IMAGE_PATH}"
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
	for toolchain in $(ls $BCDIR/toolchain)
	do
		copy_artifact $defconfig $toolchain "$BCDIR"
	done
done
