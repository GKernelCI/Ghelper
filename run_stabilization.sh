#!/bin/bash

# check the artifact directory of a build for generating LAVA jobs
# LAVA lifecycle (Generating, submit, check) is done by run_tests.py

ARCH=$1 # amd64
# make cannot handle ":" in a path, so we need to replace it
BUILDER_NAME=$2 # gentoo_sources
TOOLCHAIN_TODO="gcc"
if [ -z "$TOOLCHAIN_TODO" ];then
  echo "ERROR: I do not find the toolchain to use"
  exit 1
else
  echo "DEBUG: build use toolchain $TOOLCHAIN_TODO"
fi
BUILD_NUMBER=$3 # 16
DISCOVERY_TIME=$4
PACKAGES_ARRAY=${*:5}
FILESERVER=/var/www/fileserver/
STORAGE_SERVER=140.211.166.171:8080
SCRIPT_DIR=$(cd "$(dirname "$0")"|| exit;pwd)
echo "$PACKAGES_ARRAY"

usage() {
  echo "Usage: $0 ARCH BUILDER_NAME BUILD_NUMBER"
}

if [ -z "$ARCH" ] ;then
  usage
  exit 1
fi

if [ -z "$BUILDER_NAME" ] ;then
  usage
  exit 1
fi

if [ -z "$BUILD_NUMBER" ] ;then
  usage
  exit 1
fi

# permit to override default
if [ -e config.ini ];then
  echo "INFO: Loading default from config.ini"
  . config.ini
fi
for package in $PACKAGES_ARRAY
do
  SCANDIR="$FILESERVER/$package/$DISCOVERY_TIME/"
  if [ ! -e "$SCANDIR" ];then
    echo "ERROR: $SCANDIR does not exists"
    exit 1
  fi

  echo "CHECK $SCANDIR"
  ./deploy.py --arch "$ARCH" \
    --buildname "$BUILDER_NAME" \
    --buildnumber "$BUILD_NUMBER" \
    --toolchain "$TOOLCHAIN_TODO" \
    --defconfig "x86_64_defconfig" \
    --relpath "/$package/$DISCOVERY_TIME/"  \
    --fileserver $FILESERVER \
    --fileserverfqdn "http://$STORAGE_SERVER/" \
    --waitforjobsend \
    || exit $?
done

exit 0
