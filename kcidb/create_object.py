#!/usr/bin/env python
# -*- coding: utf-8 -*-

import json

#revisions variable
r_id="wyqnpyuntyoarnufwnpuqwypeyebf3c6a7247ae590c0d2965622961b74b6c99a92fec70d07fa4025cb6fcb944a9"
r_origin="gkernelci"
r_git_repository_url="git://git.kernel.org/pub/scm/linux/kernel/git/sashal/linux-stable.git"
r_git_repository_branch="5.8"
r_contacts=["Mike Pagano <mpagano@gentoo.org>","Alice Ferrazzi <alicef@gentoo.org>"]
r_patch_mboxes=[{"name":'test','url':'test'}]
r_log_url="https://kernel-ci.emjay-embedded.co.uk/api/v2/logs/16852/raw"
r_valid=True

#builds variable
b_id="gkernelci:50-6"
b_origin="gkernelci"
b_revision_id="wyqnpyuntyoarnufwnpuqwypeyebf3c6a7247ae590c0d2965622961b74b6c99a92fec70d07fa4025cb6fcb944a9"
b_architecture="amd64"
b_log_url="https://kernel-ci.emjay-embedded.co.uk/api/v2/logs/16853/raw"
b_valid=True
b_misc_url="https://kernel-ci.emjay-embedded.co.uk/#/builders/50/builds/6"


json_template = """
{
    "revisions": [
        {
            "id": "wyqnpyuntyoarnufwnpuqwypeyebf3c6a7247ae590c0d2965622961b74b6c99a92fec70d07fa4025cb6fcb944a9",
            "origin": "gkernelci",
            "git_repository_url": "git://git.kernel.org/pub/scm/linux/kernel/git/sashal/linux-stable.git",
            "git_repository_branch": "5.8",
            "contacts": [
                "Mike Pagano <mpagano@gentoo.org>"
            ],
            "patch_mboxes": [
                {
                    "name": "1500_XATTR_USER_PREFIX.patch",
                    "url": "https://gitweb.gentoo.org/proj/linux-patches.git/plain/1500_XATTR_USER_PREFIX.patch?h=5.8&id=1d996290ed3f1ffdc4ea2d9b4c4d2cf19ccc77d3"
                },
                {
                    "name": "1510_fs-enable-link-security-restrictions-by-default.patch",
                    "url": "https://gitweb.gentoo.org/proj/linux-patches.git/plain/1510_fs-enable-link-security-restrictions-by-default.patch?h=5.8&id=1d996290ed3f1ffdc4ea2d9b4c4d2cf19ccc77d3"
                }
            ],
            "log_url": "https://kernel-ci.emjay-embedded.co.uk/api/v2/logs/16852/raw",
            "valid": true
        }
    ],
    "builds": [
        {
            "id": "gkernelci:50-6",
            "origin": "gkernelci",
            "revision_id": "9ece50d8a470ca7235ffd6ac0f9c5f0f201fe2c8+bf3c6a7247ae590c0d2965622961b74b6c99a92fec70d07fa4025cb6fcb944a9",
            "architecture": "amd64",
            "log_url": "https://kernel-ci.emjay-embedded.co.uk/api/v2/logs/16853/raw",
            "valid": true,
            "misc": {
                "url": "https://kernel-ci.emjay-embedded.co.uk/#/builders/50/builds/6"
            }
        }
    ],
        "version": {
        "major": 3,
        "minor": 0
        }
}
"""
data = json.loads(json_template)
data['revisions'][0]['id']= r_id
data['revisions'][0]['origin']= r_origin
data['revisions'][0]['git_repository_url']= r_git_repository_url
data['revisions'][0]['git_repository_branch']= r_git_repository_branch
data['revisions'][0]['contacts']= r_contacts
data['revisions'][0]['patch_mboxes']= r_patch_mboxes
r_patch_mboxes[0]["name"] = "test"
r_patch_mboxes[0]["url"] = "https://gitweb.gentoo.org/proj/linux-patches.git/plain/1500_XATTR_USER_PREFIX.patch?h=5.8&id=1d996290ed3"
r_patch_mboxes.append({"name":"test","url":"test"})
r_patch_mboxes[1]["name"] = "test2"
r_patch_mboxes[1]["url"] = "https://gitweb.gentoo.org/proj/linux-patches.git/plain/1502_XATTR_USER_PREFIX.patch?h=5.8&id=1d996290ed3"
data['revisions'][0]['log_url']= r_log_url
data['revisions'][0]['valid']= r_valid
data['builds'][0]['id']= b_id
data['builds'][0]['origin']= b_origin
data['builds'][0]['revision_id']= b_revision_id
data['builds'][0]['architecture']= b_architecture
data['builds'][0]['log_url']= b_log_url
data['builds'][0]['valid']= b_valid
data['builds'][0]['misc']['url']= b_misc_url

with open("data_file.json", "w") as write_file:
    json.dump(data, write_file)

