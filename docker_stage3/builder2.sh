#!/bin/sh

# gentoo_docker builder step 2
# script ran inside chroot

ARCH=$1
USERID=$2
SRC_PATH=$3
FDIR=$4
NBCPU=$5

echo "BUILD: for $ARCH with $NBCPU cpus"

su - buildbot -c "/builder3.sh $*"
exit $?
