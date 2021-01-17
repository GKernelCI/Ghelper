#!/bin/bash

export GOOGLE_APPLICATION_CREDENTIALS=~/.kernelci-ci-gkernelci.json
echo "submitting data_file.json"
kcidb-submit -p kernelci-production -t playground_kernelci_new < data_file.json
echo "data_file submitted"
