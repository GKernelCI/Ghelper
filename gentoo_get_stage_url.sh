#!/bin/sh

DEBUG=0
RFS_BASE=http://ftp.free.fr/mirrors/ftp.gentoo.org/

debug() {
  if [ $DEBUG -ge 1 ];then
    echo "$*"
  fi
}

while [ $# -ge 1 ]
do
  case $1 in
  --arch)
    shift
    if [ -z "$1" ];then
      echo "ERROR: missing subargument"
      exit 1
    fi
    ARCH=$1
    case $1 in
    x86_64)
      ARCH=amd64
    ;;
    powerpc64)
      ARCH=ppc64
    ;;
    esac
    SARCH=$ARCH
    shift
  ;;
  -d)
    DEBUG=1
    shift
  ;;
  *)
    echo "ERROR: unknow argument $1"
    exit 1
  ;;
  esac
done

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
  ppc64)
    RFS_BPATH=/releases/ppc/autobuilds
    BASEURL=$RFS_BASE$RFS_BPATH
  ;;
  sparc64)
    RFS_BPATH=/releases/sparc/autobuilds
    BASEURL=$RFS_BASE$RFS_BPATH
  ;;
  x86)
    SARCH=i686
  ;;
  esac

  LATEST_TXT="latest-stage3-${SARCH}-openrc.txt"
  curl -s "$BASEURL/$LATEST_TXT" > $LATEST_TXT
  RET=$?
  grep -q '404 - Not Found' $LATEST_TXT && RET=1
  if [ $RET -ne 0 ];then
    #echo "DEBUG: retry without openrc variant"
    LATEST_TXT="latest-stage3-${SARCH}.txt"
    curl -s "$BASEURL/$LATEST_TXT" > $LATEST_TXT
    RET=$?
    if [ $RET -ne 0 ];then
      echo "ERROR: fail to grab $BASEURL/$LATEST_TXT"
      exit 1
    fi
  fi
  echo "ROOTFS_LATEST=$BASEURL/$LATEST_TXT"
  LATEST=$(grep -v ^# $LATEST_TXT | cut -d' ' -f1)
  return 0
}

found_latest || exit $?

DIGESTS_ASC=$(basename "$LATEST.asc")
DIGESTS=$(basename "$LATEST.DIGESTS")

curl -s "$BASEURL/$LATEST.DIGESTS" > $DIGESTS
if [ $? -ne 0 ];then
  echo "ERROR: fail to download $BASEURL/$LATEST.DIGESTS"
  rm $LATEST_TXT
  exit 1
fi

if [ $CHECK_SIG -eq 1 ];then
  debug "DEBUG: curl $BASEURL/$LATEST.DIGESTS.asc"
  curl -s "$BASEURL/$LATEST.asc" > $DIGESTS_ASC
  RET=$?
  if [ $RET -ne 0 ];then
    echo "ERROR: fail to download $BASEURL/$LATEST.DIGESTS.asc"
    rm ${LATEST_TXT}
    rm latest-stage3-$SARCH.DIGESTS
    exit 1
  fi

  debug "DEBUG: curl $LATEST"
  wget -q -N "$BASEURL/$LATEST"
  RET=$?
  if [ $RET -ne 0 ];then
    echo "ERROR: fail to download $BASEURL/$LATEST"
    rm ${LATEST_TXT}
    rm latest-stage3-$SARCH.DIGESTS
    exit 1
  fi

  debug "DEBUG: GPG check with $DIGESTS_ASC and $(basename $LATEST)"
  gpg --batch -q --verify "$DIGESTS_ASC" $(basename $LATEST) >gpg.out 2>gpg.err
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
