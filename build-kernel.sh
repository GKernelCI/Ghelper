#!/bin/sh

set -e
# for catching make failing but hidden by tee
set -o pipefail

NBCPU=$(getconf _NPROCESSORS_ONLN)
MAKEOPTS="-j$(( $NBCPU + 1 ))"

if [ $# -lt 1 ]; then
  echo "Usage: $(basename $0) arch BUILDER_NAME BUILD_NUMBER SOURCEDIR [build|modules]"
  exit 1
fi

ARCH=$1
# make cannot handle ":" in a path, so we need to replace it
BUILDER_NAME=$(echo $2 | sed 's,:,_,g')
BUILD_NUMBER=$3
SOURCEDIR=$4
ACTION=$5
TOOLCHAIN_TODO=$(echo $2 | cut -d: -f3)
if [ -z "$TOOLCHAIN_TODO" ];then
  echo "ERROR: I do not find the toolchain to use"
  exit 1
else
  echo "DEBUG: build use toolchain $TOOLCHAIN_TODO"
fi

# hacks before Gbuildbot has all args
if [ "$2" = 'modules' ];then
  ACTION='modules'
fi
if [ -z "$ACTION" ];then
  ACTION=build
fi

MAKEFUNC=do_make
if [ "$TOOLCHAIN_TODO" = 'gentoo' ];then
  MAKEFUNC=do_native_make
fi

do_make() {
  echo "DOMAKE $*"
  make $*
}

do_native_make() {
  echo "DOMAKE native $*"
  docker run --privileged \
    -v gdocker_worker_data:/buildbot \
    docker-stage3-$ARCH:latest /gentoo/builder.sh $ARCH $(id -u) $(pwd) $FDIR $NBCPU $*
}

# renice itself
renice -n 19 -p $$

build() {
  local defconfig="$1"
  local toolchain="$2"

  TOOLCHAIN_DIR="$TCONFIG/$HOST_ARCH/$ARCH/$toolchain"
  echo "DEBUG: found toolchain $toolchain in $TOOLCHAIN_DIR"
  if [ -e "$TOOLCHAIN_DIR/opts" ];then
    TC_OPTS="$(cat $TOOLCHAIN_DIR/opts)"
    MAKEOPTS="$TC_OPTS $MAKEOPTS"
  fi
  if [ -e "$TOOLCHAIN_DIR/version" ];then
    echo "=== version of $toolchain ==="
    $TOOLCHAIN_DIR/version
    echo "============================="
  fi

  LINUX_ARCH=$ARCH
  # insert ARCH hack for name here
  case $ARCH in
  amd64)
    LINUX_ARCH=x86_64
  ;;
  ppc64)
    LINUX_ARCH=powerpc
  ;;
  esac

  FDIR="$(dirname $(realpath $0))/linux-$ARCH-build/$BUILDER_NAME/$BUILD_NUMBER/$defconfig/$toolchain"

  echo "DEBUG: $ACTION for $ARCH/$defconfig to $FDIR"
  MAKEOPTS="$MAKEOPTS ARCH=$LINUX_ARCH O=$FDIR"

  case $ACTION in
  build)
    echo "DO: mrproper"
    $MAKEFUNC $MAKEOPTS mrproper

    echo "DO: generate config from defconfig"
    $MAKEFUNC $MAKEOPTS $defconfig | tee --append $FDIR/build.log

    if [ -e "$BCDIR/config" ];then
      cp $FDIR/.config $FDIR/.config.old
      echo "DEBUG: config hacks"
      for config in $(ls $BCDIR/config)
      do
        echo "DEBUG: add config $config"
        cat $BCDIR/config/$config >> $FDIR/.config
      done
      $MAKEFUNC $MAKEOPTS olddefconfig >> $FDIR/build.log
      diff -u $FDIR/.config.old $FDIR/.config || true
    fi

    echo "DO: build"
    $MAKEFUNC $MAKEOPTS | tee --append $FDIR/build.log
  ;;
  modules)
    rm -f $FDIR/nomodule
    grep -q 'CONFIG_MODULES=y' $FDIR/.config || touch $FDIR/nomodule
    if [ -e $FDIR/nomodule ];then
      echo "INFO: modules are disabled, skipping"
      return 0
    fi
    echo "DO: build modules"
    $MAKEFUNC $MAKEOPTS modules | tee --append $FDIR/build.log
    echo "DO: install modules"
    mkdir $FDIR/modules
    $MAKEFUNC $MAKEOPTS modules_install INSTALL_MOD_PATH="$FDIR/modules/" | tee --append $FDIR/build.log
    CPWD=$(pwd)
    cd $FDIR/modules
    echo "DO: targz modules"
    tar czf ../modules.tar.gz lib
    cd $CPWD
    rm -r "$FDIR/modules/"

  ;;
  *)
    echo "ERROR: unknow action: $ACTION"
    exit 1
  ;;
  esac
}

BCONFIG="$(dirname $(realpath $0))/build-config/"
if [ ! -e "$BCONFIG/$ARCH" ];then
  echo "ERROR: $ARCH is unsupported"
  exit 1
fi

TCONFIG=$(dirname $(realpath $0))/toolchains
HOST_ARCH=$(uname -m)
if [ ! -e "$TCONFIG/$HOST_ARCH" ];then
  echo "ERROR: build not handled for host arch $HOST_ARCH"
  exit 1
fi
if [ ! -e "$TCONFIG/$HOST_ARCH/$ARCH" ];then
  echo "ERROR: no toolchain for $ARCH"
  exit 1
fi
if [ ! -e "$TCONFIG/$HOST_ARCH/$ARCH/$TOOLCHAIN_TODO" ];then
  echo "ERROR: no toolchain $TOOLCHAIN_TODO for $ARCH"
  exit 1
fi

for defconfigdir in $(ls $BCONFIG/$ARCH)
do
  echo "INFO: $ARCH $defconfigdir"
  BCDIR=$BCONFIG/$ARCH/$defconfigdir
  if [ -e $BCDIR/defconfig ];then
    defconfig="$(cat $BCDIR/defconfig)"
  else
    echo "ERROR: no defconfig in $BCDIR, defaulting to defconfig"
    defconfig="defconfig"
  fi
  build $defconfig $TOOLCHAIN_TODO
done
