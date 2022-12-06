#!/bin/bash

MAKEOPTS="-j$(( $(getconf _NPROCESSORS_ONLN) + 1 ))"
currentdate=$1
FILESERVER=/var/www/fileserver/
# only [a-zA-Z0-9][a-zA-Z0-9_.-] are allowed as docker container name
currentdate_sanitized=${currentdate//:/.}
currentdate_sanitized=${currentdate_sanitized//,/_}
currentdate_sanitized=${currentdate_sanitized//+/-}

gentoo_rootfs=$(docker run -d --name gentoo"${currentdate_sanitized}" gentoo/stage3:latest tail -f /dev/null)

# cleaning gentoo docker container
function cleanup {
  echo "removing docker image ${gentoo_rootfs}"
  docker stop "${gentoo_rootfs}" || exit $?
  docker rm "${gentoo_rootfs}" || exit $?
}

fileserver=()
fileserver_index=0

# be sure to remove gentoo docker container on EXIT
trap cleanup EXIT

for kernel_sources in "${@:2}"; do 
  if [[ "${kernel_sources}" =~ .ebuild$ ]]; then
    if [[ "${kernel_sources}" =~ sources ]]; then
      echo "DEBUG: use $gentoo_rootfs as docker image"
      # gentoolkit need PYTHON_TARGETS
      docker exec "${gentoo_rootfs}" sed -i '$ a PYTHON_TARGETS="python3_9"' /etc/portage/make.conf || exit $?
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
      docker exec -w /usr/src/linux "${gentoo_rootfs}" make defconfig || exit $?
      docker exec -w /usr/src/linux "${gentoo_rootfs}" make $MAKEOPTS || exit $?
      # create the fileserver folder if dosen't exist
      mkdir -p "${FILESERVER}"/"${kernel_sources}"/"${currentdate}"/ || exit $?
      docker cp "${gentoo_rootfs}":/usr/src/linux/arch/x86/boot/bzImage "${FILESERVER}"/"${kernel_sources}"/"${currentdate}"/ || exit $?
      docker cp "${gentoo_rootfs}":/usr/src/linux/.config "${FILESERVER}"/"${kernel_sources}"/"${currentdate}"/config || exit $?
      # set fileserver
      fileserver[fileserver_index]="/${kernel_sources}/${currentdate}/ " || exit $?
      fileserver_index=$(( fileserver_index+=1 )) || exit $?
    fi
  fi
done

echo "FILESERVERS=${fileserver[*]}"
