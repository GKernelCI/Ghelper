#!/usr/bin/env python
# -*- coding: utf-8 -*-

import glob
import ntpath

def get_patches_list(kernel_major_version):
    patches_list=[]
    path = '../linux-patches/*.patch'
    files = glob.glob(path)
    sorted_files=sorted(files)
    for filename in sorted_files:
        patchbasename=(ntpath.basename(filename))
        print(patchbasename)
        patch_name=patchbasename
        patch_url="https://raw.githubusercontent.com/GKernelCI/linux-patches/" + kernel_major_version + "/" + patchbasename
        patches_list.append({'name':patch_name, 'url':patch_url})
    return(patches_list)
