#!/bin/bash

MAKEOPTS="-j$(( $(getconf _NPROCESSORS_ONLN) + 1 ))"
currentdate=$(date +%Y%m%d_%H%M%S)
FILESERVER=/var/www/fileserver/

for kernel_sources in "$@"; do 
  if [[ "${kernel_sources}" =~ .ebuild$ ]]; then
    if [[ "${kernel_sources}" =~ sources ]]; then
      gentoo_rootfs=$(docker run -d --name gentoo"${currentdate}" gentoo/stage3:latest tail -f /dev/null)
      echo "DEBUG: use $gentoo_rootfs as docker image"
      docker exec "${gentoo_rootfs}" wget --quiet https://github.com/gentoo/gentoo/archive/master.zip -O /master.zip || exit $?
      docker exec "${gentoo_rootfs}" unzip -q master.zip || exit $?
      libself_recent_ebuild=$(docker exec "${gentoo_rootfs}" find /gentoo-master/dev-libs/libelf/ -iname "*.ebuild" | sort -Vr | head -n 1)
      bc_recent_ebuild=$(docker exec "${gentoo_rootfs}" find /gentoo-master/sys-devel/bc -iname "*.ebuild" | sort -Vr | head -n 1)
      docker exec "${gentoo_rootfs}" /usr/bin/ebuild "${libself_recent_ebuild}" clean merge || exit $?
      docker exec "${gentoo_rootfs}" /usr/bin/ebuild "${bc_recent_ebuild}" clean merge || exit $?
      docker exec "${gentoo_rootfs}" /usr/bin/ebuild /gentoo-master/"${kernel_sources}" clean merge || exit $?
      docker exec "${gentoo_rootfs}" ls /usr/src/linux -la || exit $?
      docker exec -w /usr/src/linux "${gentoo_rootfs}" make defconfig || exit $?
      docker exec -w /usr/src/linux "${gentoo_rootfs}" make $MAKEOPTS "$*" || exit $?
      docker cp "${gentoo_rootfs}":/usr/src/linux/arch/x86/boot/bzImage "${FILESERVER}"/"${kernel_sources}"/"${currentdate}"/ || exit $?
      docker stop "${gentoo_rootfs}" || exit $?
      docker rm "${gentoo_rootfs}" || exit $?
    fi
  fi
done

