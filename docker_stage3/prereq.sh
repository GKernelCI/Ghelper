#!/bin/sh

ARCH=$1
if [ -z "$ARCH" ];then
	echo "MISSING ARCH"
	exit 1
fi

echo "Enable binfmts"
update-binfmts --enable || exit $?

FST3=/buildbot/gentoo-$ARCH

echo "COPY $ARCH stage3 to $FST3"
rsync -ar --delete /gentoo/ $FST3/ || exit $?

mount -t proc none $FST3/proc || exit $?
mount --rbind /dev $FST3/dev || exit $?
mount --rbind /sys $FST3/sys || exit $?

echo "DEBUG: mount binpkgs"
mkdir -p /binpkgs/$ARCH || exit $?
mount -o bind /binpkgs/$ARCH $FST3/var/cache/binpkgs || exit $?

echo "DEBUG: list all pkgs"
find $FST3/var/cache/binpkgs

chroot $FST3 /prereq2.sh $*
exit $?
