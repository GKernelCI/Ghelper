#!/usr/bin/env python
# -*- coding: utf-8 -*-

def get_patches_list(kernel_major_version):
    patches_list=[]
    file_name="../linux-patches/0000_README"
    with open(file_name, 'r') as read_obj:
        patch_name=""
        patch_url=""
        count=0
        for line in read_obj:
            if "Patch:" in line:
                patch_name=line.strip("\n")
                patch_name=patch_name.replace("Patch:","")
                patch_name=patch_name.strip(" ")
                count += 1
            if "From:" in line:
                patch_url="https://raw.githubusercontent.com/GKernelCI/linux-patches/" + kernel_major_version + "/" + patch_name
                count += 1
            if count==2:
                patches_list.append({'name':patch_name, 'url':patch_url})
                count=0
    return(patches_list)

