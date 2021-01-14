#!/bin/bash

ARCH=$1
BUILDER_NAME=$2
BUILD_NUMBER=$3
FILESERVER=/var/www/fileserver/
LAVA_SERVER=140.211.166.173:10080
STORAGE_SERVER=140.211.166.171:8080
SCRIPT_DIR=$(cd "$(dirname "$0")"|| exit;pwd)

tmpyml=$(mktemp "/tmp/XXXXXX.yml")

KERNEL_STORAGE_URL=http://"${STORAGE_SERVER}"/"${BUILDER_NAME}"/"${BUILD_NUMBER}"/bzImage
sed -e "s@KERNEL_IMAGE_URL@${KERNEL_STORAGE_URL}@g" ${SCRIPT_DIR}/lava/job/gentoo-boot.yml > $tmpyml

lavacli -i buildbot jobs submit "$tmpyml"
rm -f "$tmpyml"
