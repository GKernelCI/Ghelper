#!/bin/bash

ARCH=$1
# make cannot handle ":" in a path, so we need to replace it
BUILDER_NAME=$(echo $2 | sed 's,:,_,g')
BUILD_NUMBER=$3
FILESERVER=/var/www/fileserver/
LAVA_SERVER=140.211.166.173:10080
STORAGE_SERVER=140.211.166.171:8080
SCRIPT_DIR=$(cd "$(dirname "$0")"|| exit;pwd)

tmpyml=$(mktemp "/tmp/XXXXXX.yml")


start_job_get_job_id() {
  lavacli -i buildbot jobs submit "$tmpyml"
  rm -f "$tmpyml"
}

get_job_state() {
  lavacli --id buildbot jobs show "${job_id}" | grep "state       :" | awk '{print $3}'
}

get_failed_results() {
  lavacli -i buildbot results "${job_id}" | grep fail | awk '{ print $2 }'
}

check_job_state() {
  job_state="$(get_job_state)"
  if [[ $job_state != "Finished" ]]; then
    echo -n -e "The job $job_id is $job_state"
    while [[ $job_state != "Finished" ]]; do
      job_state="$(get_job_state)"
      sleep 5
      echo -n -e "."
    done
  fi
  echo The job "${job_id}" is "${job_state}"
}

skip_usual_failing_task() {
  failed_tasks=$(get_failed_results)
  line=1
  for output_line in $failed_tasks
  do
    line_string=$(awk -v linevar=$line 'NR==linevar {print; exit}' skip/kselftest_skiplist )
    if [ "$output_line" = "$line_string" ]; then
      echo "$line_string [Skipped]"
    else
      echo "$output_line [Failed] not on the skip list"
      exit 1
    fi
    line=$(($line + 1))
  done
}

display_lava_url () {
  echo "LAVAJOB_URL=http://$LAVA_SERVER/scheduler/job/$job_id"
}

configure_lava_boot() {
  KERNEL_STORAGE_URL=http://"${STORAGE_SERVER}/${BUILDER_NAME}/$ARCH/${BUILD_NUMBER}/defconfig/gcc/bzImage"
  latest_stage3_amd64=$(curl -s http://gentoo.mirrors.ovh.net/gentoo-distfiles/releases/amd64/autobuilds/latest-stage3-amd64.txt)
  rootfs_url=$(echo "$latest_stage3_amd64" | awk 'NR==3{ print $1 }')
  rootfs_digests_file=$(curl -s http://gentoo.mirrors.ovh.net/gentoo-distfiles/releases/amd64/autobuilds/"$rootfs_url".DIGESTS)
  rootfs_digest=$(echo "$rootfs_digests_file" | awk 'NR==2{ print $1 }')
  rootfs_fullurl=http://gentoo.mirrors.ovh.net/gentoo-distfiles/releases/amd64/autobuilds/"$rootfs_url"
  sed -e "s@KERNEL_IMAGE_URL@${KERNEL_STORAGE_URL}@g" -e "s@ROOTFS_HASH@${rootfs_digest}@g" \
  -e "s@ROOTFS_URL@${rootfs_fullurl}@g" "${SCRIPT_DIR}"/lava/job/gentoo-boot.yml > "$tmpyml"
  add_kselftest
}

add_kselftest(){
  cat "${SCRIPT_DIR}"/lava/job/gentoo-kselftest.yml >> "$tmpyml"
}

configure_lava_boot
job_id=$(start_job_get_job_id)
display_lava_url
check_job_state
skip_usual_failing_task
