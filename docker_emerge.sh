#!/bin/bash

MAKEOPTS="-j$(( $(getconf _NPROCESSORS_ONLN) + 1 ))"
ARCH=$1
CURRENTDATE=$2
FILESERVER=/var/www/fileserver/
# only [a-zA-Z0-9][a-zA-Z0-9_.-] are allowed as docker container name
currentdate_sanitized=${CURRENTDATE//:/.}
currentdate_sanitized=${currentdate_sanitized//,/_}
currentdate_sanitized=${currentdate_sanitized//+/-}

gentoo_rootfs=$(docker run -d --platform="$ARCH" --name gentoo"${currentdate_sanitized}" gentoo/stage3:latest tail -f /dev/null)

# cleaning gentoo docker container
function cleanup {
  echo "removing docker image ${gentoo_rootfs}"
  docker stop "${gentoo_rootfs}" || exit $?
  docker rm "${gentoo_rootfs}" || exit $?
}

LINUX_ARCH=$ARCH
IMAGE_ARCH=$ARCH
# insert ARCH hack for name here
case $ARCH in
amd64)
  LINUX_ARCH=x86_64
  IMAGE_ARCH=x86
  IMAGE_FILE=bzImage
;;
ppc64)
  LINUX_ARCH=powerpc
  IMAGE_FILE=vmlinux
;;
386)
  LINUX_ARCH=i386
  IMAGE_ARCH=x86
  IMAGE_FILE=bzImage
;;
arm)
  IMAGE_ARCH=arm
  IMAGE_FILE=zImage
;;
arm64)
  IMAGE_ARCH=arm64
  IMAGE_FILE=Image
;;
esac
MAKEOPTS="$MAKEOPTS ARCH=$LINUX_ARCH"

fileserver=()
fileserver_index=0

# be sure to remove gentoo docker container on EXIT
trap cleanup EXIT

for kernel_sources in "${@:2}"; do 
  if [[ "${kernel_sources}" =~ .ebuild$ ]]; then
    if [[ "${kernel_sources}" =~ sources ]]; then
      echo "DEBUG: use $gentoo_rootfs as docker image"
      # gentoolkit need PYTHON_TARGETS
      docker exec "${gentoo_rootfs}" sed -i '$ a PYTHON_TARGETS="python3_10"' /etc/portage/make.conf || exit $?
      docker exec "${gentoo_rootfs}" wget --quiet https://github.com/gentoo/gentoo/archive/master.zip -O /master.zip || exit $?
      docker exec "${gentoo_rootfs}" unzip -q master.zip || exit $?
      docker exec "${gentoo_rootfs}" ln -s /gentoo-master /var/db/repos/gentoo || exit $?
      # remove all "Unable to unshare: EPERM message"
      docker exec "${gentoo_rootfs}" sed -i '$ a FEATURES="-ipc-sandbox -network-sandbox"' /etc/portage/make.conf || exit $?
      docker exec "${gentoo_rootfs}" emerge --nospinner -v virtual/libelf sys-devel/bc gentoolkit|| exit $?
      # We need symlink USE for portage generate /usr/src/linux symlink
      docker exec "${gentoo_rootfs}" euse --enable symlink || exit $?
      docker exec "${gentoo_rootfs}" /usr/bin/ebuild /gentoo-master/"${kernel_sources}" clean merge || exit $?
      docker exec "${gentoo_rootfs}" ls /usr/src/linux -la || exit $?
      # build kernel
      docker exec "${gentoo_rootfs}" mkdir -p /opt/modules/ || exit $?
      docker exec -w /usr/src/linux "${gentoo_rootfs}" bash -c "make $MAKEOPTS defconfig | tee --append /opt/build.log" || exit $?
      docker exec -w /usr/src/linux "${gentoo_rootfs}" bash -c "make $MAKEOPTS | tee --append /opt/build.log" || exit $?
      # build modules
      docker exec -w /usr/src/linux "${gentoo_rootfs}" bash -c "make $MAKEOPTS modules | tee --append /opt/build.log" || exit $?
      docker exec -w /usr/src/linux "${gentoo_rootfs}" bash -c "make $MAKEOPTS modules_install INSTALL_MOD_PATH='/opt/modules/' | tee --append /opt/build.log" || exit $?
      docker exec -w /opt/modules "${gentoo_rootfs}" tar czf ../modules.tar.gz lib  || exit $?
      # create the fileserver folder if dosen't exist
      FILESERVER_FULL_DIR="${FILESERVER}/${kernel_sources}/${ARCH}/${CURRENTDATE}/"
      mkdir -p "$FILESERVER_FULL_DIR" || exit $?
      docker cp "${gentoo_rootfs}":/usr/src/linux/arch/${IMAGE_ARCH}/boot/bzImage "$FILESERVER_FULL_DIR" || exit $?
      docker cp "${gentoo_rootfs}":/usr/src/linux/.config "$FILESERVER_FULL_DIR"/config || exit $?
      docker cp "${gentoo_rootfs}":/opt/modules.tar.gz "$FILESERVER_FULL_DIR" || exit $?
      docker cp "${gentoo_rootfs}":/opt/build.log "$FILESERVER_FULL_DIR" || exit $?
      # set fileserver
      fileserver[fileserver_index]="/${kernel_sources}/${ARCH}/${CURRENTDATE}/" || exit $?
      fileserver_index=$(( fileserver_index+=1 )) || exit $?
    fi
  fi
done

echo "FILESERVERS=${fileserver[*]}"
