#!/bin/sh

DEBUG=0
RFS_BASE=http://gentoo.mirrors.ovh.net/gentoo-distfiles/
RFS_BASE=http://ftp.free.fr/mirrors/ftp.gentoo.org/
ARCH_OPTION=""

debug() {
	if [ $DEBUG -eq 1 ];then
		echo "$*"
	fi
}

while [ $# -ge 1 ]
do
	case $1 in
	-d)
		DEBUG=1
		shift
	;;
	--arch)
		shift
		if [ -z "$1" ];then
			echo "ERROR: missing subargument"
			exit 1
		fi
		debug "DEBUG: set arch to $1"
		ARCH=$1
		case $1 in
		armel)
			ARCH=arm
		;;
		armbe)
			echo "ERROR: armbe not supported by gentoo"
			exit 1
		;;
		powerpc)
			ARCH=ppc
		;;
		esac
		if [ "$ARCH" = 'x86_64' ];then
			ARCH=amd64
		fi
		SARCH=$ARCH
		shift
	;;
	*)
		echo "ERROR: unknow argument $1"
		exit 1
	;;
	esac
done

debug "end of args"

if [ -z "$ARCH" ];then
	echo "ERROR: arch is not set"
	exit 1
fi

CHECK_SIG=1

found_latest()
{
	RFS_BPATH=/releases/$ARCH/autobuilds
	BASEURL=$RFS_BASE$RFS_BPATH
	case $ARCH in
	arm)
		SARCH=armv7a_hardfp
	;;
	arm64)
		RFS_BPATH=/experimental/$ARCH
		BASEURL=$RFS_BASE$RFS_BPATH
		curl -s "$BASEURL/" > index.html
		if [ ! -e index.html ];then
			echo "ERROR: no index from $BASEURL"
			return 1
		fi
		STAGE3=$(grep -o '"stage3-arm64-[0-9]*.tar.bz2"' index.html | cut -d'"' -f2)
		LATEST=$STAGE3
		CHECK_SIG=0
		rm index.html
		return 0
	;;
	sparc64)
		RFS_BPATH=/releases/sparc/autobuilds
		BASEURL=$RFS_BASE$RFS_BPATH
	;;
	ppc64)
		RFS_BPATH=/releases/ppc/autobuilds
		BASEURL=$RFS_BASE$RFS_BPATH
	;;
	hppa)
		ARCH_OPTION="1.1"
	;;
	m68k)
		RFS_BPATH=/experimental/$ARCH/
		BASEURL=$RFS_BASE$RFS_BPATH
		LATEST="stage3-m68k-20130509.tar.bz2"
		CHECK_SIG=0
		return
	;;
	mips)
		RFS_BPATH=/experimental/$ARCH/autobuilds
		BASEURL=$RFS_BASE$RFS_BPATH
		# TODO
		exit 1
	;;
	x86)
		SARCH=i686
	;;
	esac

	LATEST_TXT="latest-stage3-${SARCH}${ARCH_OPTION}.txt"
	curl -s "$BASEURL/$LATEST_TXT" > $LATEST_TXT
	RET=$?
	if [ $RET -ne 0 ];then
		echo "ERROR: fail to grab $BASEURL/$LATEST_TXT"
		exit 1
	fi
	echo "ROOTFS_LATEST=$BASEURL/$LATEST_TXT"
	LATEST=$(grep -v ^# $LATEST_TXT | cut -d' ' -f1)
	return 0
}

found_latest || exit $?

debug "Found latest success"

DIGESTS_ASC=$(basename "$LATEST.DIGESTS.asc")
DIGESTS=$(basename "$LATEST.DIGESTS")

curl -s "$BASEURL/$LATEST.DIGESTS" > $DIGESTS
if [ $? -ne 0 ];then
	echo "ERROR: fail to download $BASEURL/$LATEST.DIGESTS"
	rm $LATEST_TXT
	exit 1
fi

if [ $CHECK_SIG -eq 1 ];then
	curl -s "$BASEURL/$LATEST.DIGESTS.asc" > $DIGESTS_ASC
	RET=$?
	if [ $RET -ne 0 ];then
		echo "ERROR: fail to download $BASEURL/$LATEST.DIGESTS.asc"
		rm latest-stage3-$SARCH.txt
		rm latest-stage3-$SARCH.DIGESTS
		exit 1
	fi

	gpg --batch -q --verify "$DIGESTS_ASC" >gpg.out 2>gpg.err
	RET=$?
	if [ $RET -ne 0 ];then
		echo "ERROR: GPG fail to verify"
		cat gpg.out
		cat gpg.err
		rm gpg.err gpg.out
		exit 1
	fi
	rm gpg.err gpg.out
fi

echo "ROOTFS_URL=$BASEURL/$LATEST"
echo "ROOTFS_BASE=$RFS_BASE"
echo "ROOTFS_PATH=$RFS_BPATH/$LATEST"
#cat $(basename $LATEST.DIGESTS) |
while read -r line
do
	echo "$line" | grep -q SHA512
	RET=$?
	if [ $RET -eq 0 ];then
		read line
		LATEST_BASENAME=$(basename "$LATEST")
		echo "$line" | grep -q "$LATEST_BASENAME$"
		RET=$?
		if [ $RET -eq 0 ];then
			ROOTFS_SHA512=$(echo "$line" | cut -d' ' -f1)
			echo "ROOTFS_SHA512=$ROOTFS_SHA512"
		fi
	fi
done < "$DIGESTS"

rm "$DIGESTS"
if [ $CHECK_SIG -eq 1 ];then
	rm "$DIGESTS_ASC"
fi
if [ -e "$LATEST_TXT" ];then
	rm "$LATEST_TXT"
fi
