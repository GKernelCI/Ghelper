#!/bin/sh

# gentoo_docker builder step 2
# script ran inside chroot

ARCH=$1
USERID=$2
NBCPU=$3

echo "BUILD: for $ARCH with $NBCPU cpus"

# clean news output
echo "DEBUG: clean news"
eselect news read --quiet all
eselect news purge

echo "MAKEOPTS=-j$NBCPU" >> /etc/portage/make.conf
emerge --info || exit $?
time emerge --nospinner --quiet --color n -bk -v sys-devel/bc virtual/libelf || exit $?

grep -q buildbot /etc/passwd
if [ $? -eq 0 ];then
	echo "SKIP: buildbot user already exists"
else
	echo "Create buildbot user with UID=$USERID"
	useradd --uid $USERID buildbot || exit $?
fi
