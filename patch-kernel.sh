#!/bin/sh
set -eu

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-hv] [-k] [KERNEL VERSION]
Do stuff with FILE and write the result to standard output. With no FILE
or when FILE is -, read standard input.

    -a          kernel architecture to use for search configuration file.
    -h          display this help and exit
    -k          use the kernel version for search configuration file.
    -v          verbose mode. Can be used multiple times for increased
                verbosity.
EOF
}

# Initialize our own variables:
kernel_version=""
kernel_arch="amd64"
verbose=0

OPTIND=1
# Resetting OPTIND is necessary if getopts was used previously in the script.
# It is a good idea to make OPTIND local if you process options in a function.

while getopts a:hvk: opt; do
    case $opt in
        a)
            kernel_arch=$OPTARG
            ;;
        h)
            show_help
            exit 0
            ;;
        v)  verbose=$((verbose+1))
            ;;
        k)  kernel_version=$OPTARG
            ;;
        *)
            show_help >&2
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --.

kernel_arch_target="x86_64"
if [ $kernel_arch = "arm" ]; then
	kernel_arch_target="arm"
fi

# End of file
for i in ../linux-patches/*.patch; do
	echo "${i}"
	yes "" | patch -p1 --no-backup-if-mismatch -f -N -s -d linux-*/ < "${i}";
done
