#!/bin/sh

# gentoo_docker builder step 3 (final step)
# script ran inside chroot under build user

echo "DEBUG: $0 called with $*"

ARCH=$1
USERID=$2
SRC_PATH="$3"
FDIR=$4
NBCPU=$5
shift
shift
shift
shift
shift

echo "BUILD for $ARCH as user $(id -u -n) with MAKEOPTS=$*"

echo "DEBUG: uname give $(uname -a)"

if [ -z "$ARCH" ];then
	echo "ARCH is not set"
	exit 1
fi

cd $SRC_PATH || exit $?
make $*
exit $?

