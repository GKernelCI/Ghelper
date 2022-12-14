#!/bin/bash
#
# Check if "*-sources" package exist
# Return True if exist and False if not

PACKAGES_ARRAY=${*:1}
SCRIPT_DIR=$(cd "$(dirname "$0")"|| exit;pwd)
ROOT=$(cd "${SCRIPT_DIR}/../"|| exit;pwd)
GENTOO_ROOT=$(cd "${ROOT}/gentoo/"|| exit;pwd)


package_exist() {
  if [ -e "${GENTOO_ROOT}/${package}" ]; then
    do_exist="True"
  fi
}

do_exist="False"
for package in $PACKAGES_ARRAY
do
    package_exist
done

echo "$do_exist"
