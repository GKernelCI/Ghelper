#!/bin/sh

# gentoo_docker builder step 1
# script preparing chroot

ARCH=$1
if [ -z "$ARCH" ];then
	exit 1
fi

update-binfmts --enable || exit $?

FST3=/buildbot/gentoo-$ARCH
mount -t proc none $FST3/proc || exit $?
mount --rbind /dev $FST3/dev || exit $?
mount --rbind /sys $FST3/sys || exit $?

mkdir -p $FST3/buildbot || exit $?
mount -o bind /buildbot $FST3/buildbot || exit $?

echo "DEBUG: release"
lsb_release
cat /etc/debian_version

echo "DEBUG: chroot in $FST3"
chroot $FST3 /builder2.sh $*
exit $?
