#!/bin/bash

ARCH=$1
BUILDER_NAME=$2
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

get_job_results() {
  lavacli -i buildbot results "${job_id}"
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

get_failed_tasks() {
  echo "$(get_job_results)" | grep fail
}

check_tasks() {
  failed_tasks="$(get_failed_tasks)"
  if [ "$failed_tasks" ]; then
    echo "Following lava tasks failed"
    echo "$failed_tasks"
    # failing this task
    exit 1
  else
    echo "Lava tasks runned succesfully"
    echo "$get_job_results"
  fi
}

display_lava_url () {
  echo "LAVAJOB_URL=http://$LAVA_SERVER/scheduler/job/$job_id"
}

configure_lava_boot() {
  KERNEL_STORAGE_URL=http://"${STORAGE_SERVER}"/"${BUILDER_NAME}"/"${BUILD_NUMBER}"/bzImage
  latest_stage3_amd64=$(curl -s http://gentoo.mirrors.ovh.net/gentoo-distfiles/releases/amd64/autobuilds/latest-stage3-amd64.txt)
  rootfs_url=$(echo "$latest_stage3_amd64" | awk 'NR==3{ print $1 }')
  rootfs_digests_file=$(curl -s http://gentoo.mirrors.ovh.net/gentoo-distfiles/releases/amd64/autobuilds/"$rootfs_url".DIGESTS)
  rootfs_digest=$(echo "$rootfs_digests_file" | awk 'NR==2{ print $1 }')
  rootfs_fullurl=http://gentoo.mirrors.ovh.net/gentoo-distfiles/releases/amd64/autobuilds/"$rootfs_url"
  sed -e "s@KERNEL_IMAGE_URL@${KERNEL_STORAGE_URL}@g" -e "s@ROOTFS_HASH@${rootfs_digest}@g" \
  -e "s@ROOTFS_URL@${rootfs_fullurl}@g" "${SCRIPT_DIR}"/lava/job/gentoo-boot.yml > "$tmpyml"
}

configure_lava_boot
job_id=$(start_job_get_job_id)
display_lava_url
check_job_state
check_tasks
