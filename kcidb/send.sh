#!/bin/bash

export GOOGLE_APPLICATION_CREDENTIALS=~/.kernelci-ci-gkernelci.json
validate=$(kcidb-validate < data_file.json)
if [[ $? != 0 ]]; then
  # validation of data_file.json failed
  echo "validation failed"
  exit 1
fi
echo "validation passed"
echo "submitting data_file.json"
kcidb-submit -p kernelci-production -t kernelci_new < data_file.json
