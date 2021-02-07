#!/bin/bash

MAKEOPTS="-j$(( $(getconf _NPROCESSORS_ONLN) + 1 ))"
currentdate=$(date +%Y%m%d_%H%M%S)
FILESERVER=/var/www/fileserver/

for kernel_sources in "$@"; do 
  if [[ "${kernel_sources}" =~ .ebuild$ ]]; then
    if [[ "${kernel_sources}" =~ sources ]]; then
      gentoo_rootfs=$(docker run -d --name gentoo"${currentdate}" gentoo/stage3-amd64:latest tail -f /dev/null)
      docker exec "${gentoo_rootfs}" wget https://github.com/gentoo/gentoo/archive/master.zip -O /master.zip
      docker exec "${gentoo_rootfs}" unzip master.zip
      libself_recent_ebuild=$(docker exec "${gentoo_rootfs}" find /gentoo-master/dev-libs/libelf/ -iname "*.ebuild" | sort -Vr | head -n 1)
      bc_recent_ebuild=$(docker exec "${gentoo_rootfs}" find /gentoo-master/sys-devel/bc -iname "*.ebuild" | sort -Vr | head -n 1)
      docker exec "${gentoo_rootfs}" /usr/bin/ebuild "${libself_recent_ebuild}" clean merge
      docker exec "${gentoo_rootfs}" /usr/bin/ebuild "${bc_recent_ebuild}" clean merge
      docker exec "${gentoo_rootfs}" /usr/bin/ebuild /gentoo-master/"${kernel_sources}" clean merge
      docker exec "${gentoo_rootfs}" ls /usr/src/linux -la
      docker exec -w /usr/src/linux "${gentoo_rootfs}" make defconfig
      docker exec -w /usr/src/linux "${gentoo_rootfs}" make $MAKEOPTS "$*"
      docker exec cp "${gentoo_rootfs}":/usr/src/linux/arch/x86/boot/bzImage "${FILESERVER}"/"${kernel_sources}"/"${currentdate}"/
      docker stop "${gentoo_rootfs}"
      docker rm "${gentoo_rootfs}"
    fi
  fi
done

