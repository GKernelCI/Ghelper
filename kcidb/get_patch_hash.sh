#!/bin/bash

patchset_folder=../linux-patches/

sha256sum "${patchset_folder}"*.patch | cut -c-64 | sha256sum | cut -c-64
