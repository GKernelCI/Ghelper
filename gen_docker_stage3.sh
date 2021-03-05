#!/bin/bash

NBCPU=$(getconf _NPROCESSORS_ONLN)
ARCH=$1

echo "gen docker stage3 for arch $ARCH"

./gentoo_get_stage_url.sh --arch $ARCH > stage3.env
. ./stage3.env

if [ -z "$ROOTFS_URL" ];then
	exit 1
fi

echo "BUILD with stage3_url=$ROOTFS_URL"
docker build --build-arg stage3_url=$ROOTFS_URL -t docker-stage3-$ARCH:latest docker_stage3 || exit $?

echo "Installing pre-requisites"
docker run --privileged \
	-v gdocker_worker_data:/buildbot \
	-v cache_pkgbin:/binpkgs \
	docker-stage3-$ARCH:latest /gentoo/prereq.sh $ARCH $(id -u) $NBCPU
