#!/bin/bash

VERSION=$1

curl -s https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/?h=v"${VERSION}" 2>&1 | head -n 1 | awk '{ print $2 }'
