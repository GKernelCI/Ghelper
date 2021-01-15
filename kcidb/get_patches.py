#!/usr/bin/env python
# -*- coding: utf-8 -*-

def get_patches_list():
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
                patch_url=line.strip("\n")
                patch_url=patch_url.replace("From:","")
                patch_url=patch_url.strip(" ")
                count += 1
            if count==2:
                patches_list.append({'name':patch_name, 'url':patch_url})
                count=0
    return(patches_list)

