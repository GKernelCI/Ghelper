#!/bin/bash

ARCH=$1
BUILDER_NAME=$2
BUILD_NUMBER=$3
FILESERVER=/var/www/fileserver/

FDIR="linux-$ARCH-build"

IMAGE_PATH="$FDIR/arch/x86/boot/bzImage"
COPY_IMAGE_PATH="${FILESERVER}"/"${BUILDER_NAME}"/"${BUILD_NUMBER}"/
mkdir -p "${COPY_IMAGE_PATH}"
chmod -R 755 "${COPY_IMAGE_PATH}"

cp -rf "${IMAGE_PATH}" "${COPY_IMAGE_PATH}"
chmod 755 "${COPY_IMAGE_PATH}"/*
