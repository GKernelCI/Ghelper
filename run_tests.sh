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
  ./gentoo_get_stage_url.sh --arch amd64 > stage-env
  . ./stage-env
  rm ./stage-env
  KERNEL_STORAGE_URL=http://"${STORAGE_SERVER}/${BUILDER_NAME}/$ARCH/${BUILD_NUMBER}/$defconfig/$toolchain/bzImage"
  sed -e "s@KERNEL_IMAGE_URL@${KERNEL_STORAGE_URL}@g" -e "s@ROOTFS_HASH@${ROOTFS_SHA512}@g" \
  -e "s@ROOTFS_URL@${ROOTFS_URL}@g" "${SCRIPT_DIR}"/lava/job/gentoo-boot.yml > "$tmpyml"
  add_kselftest
}

add_kselftest(){
  cat "${SCRIPT_DIR}"/lava/job/gentoo-kselftest.yml >> "$tmpyml"
}

SCANDIR="$FILESERVER/$BUILDER_NAME/$ARCH/$BUILD_NUMBER/"
if [ ! -e "$SCANDIR" ];then
	echo "ERROR: $SCANDIR does not exists"
	exit 1
fi

echo "CHECK $SCANDIR"
for defconfig in $(ls $SCANDIR)
do
	echo "CHECK: $defconfig"
	for toolchain in gcc
	do
		echo "CHECK: toolchain $toolchain"
		configure_lava_boot
		job_id=$(start_job_get_job_id)
		display_lava_url
		check_job_state
		skip_usual_failing_task
		echo "BOOT: $SCANDIR/$defconfig/$toolchain"
		if [ $? -ne 0 ];then
			echo "ERROR: there is some fail"
			exit 1
		fi
	done
done
