#!/usr/bin/env python
# -*- coding: utf-8 -*-

import json
import subprocess
import argparse
from configparser import ConfigParser
from get_patches import get_patches_list


conf_parser = argparse.ArgumentParser(
    # Turn off help, so we print all options in response to -h
    add_help=False
)
conf_parser.add_argument("-c", "--conf_file",
                         help="Specify config file", metavar="FILE")
args, remaining_argv = conf_parser.parse_known_args()
defaults = {
    "version": "4.9",
    "result": "Failed",
    "architecture": "amd64",
}
if args.conf_file:
    config = ConfigParser()
    config.read([args.conf_file])
    defaults = dict(config.items("Defaults"))

# Don't suppress add_help here so it will handle -h
parser = argparse.ArgumentParser(
    # Inherit options from config_parser
    parents=[conf_parser],
    # print script description with -h/--help
    description=__doc__,
    # Don't mess with format of description
    formatter_class=argparse.RawDescriptionHelpFormatter,
)
parser.set_defaults(**defaults)
parser.add_argument("-version", "--version", help="version number",
                    required=True)
parser.add_argument("-result", "--result", help="Test result",
                    required=True)
parser.add_argument("-arch", "--arch", help="Architecture tested",
                    required=True)
args = parser.parse_args(remaining_argv)


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


kernel_version=args.version
def get_r_id():
    return subprocess.run(["./kcidb/get_patch_hash.sh"], stdout=subprocess.PIPE, text=True)

patchset_hash=str(get_r_id().stdout).strip("\n")

def get_kernel_hash(kernel_version):
    return subprocess.run(["./kcidb/get_kernel_hash.sh",kernel_version], stdout=subprocess.PIPE, text=True)

base_kernel_hash=str(get_kernel_hash(kernel_version).stdout).strip("\n")

json_template = """
{
    "revisions": [
        {
            "id": "2c85ebc57b3e1817b6ce1a6b703928e113a90442",
            "origin": "gkernelci",
            "git_repository_url": "git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git",
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

def create_object(r_id, r_origin, r_git_repository_url, 
                  r_git_repository_branch, r_contacts, 
                  r_patch_mboxes, r_log_url, r_valid, 
                  b_id, b_origin, b_revision_id, b_architecture, 
                  b_log_url, b_valid, b_misc_url):
    data = json.loads(json_template)
    data['revisions'][0]['id']= r_id
    data['revisions'][0]['origin']= r_origin
    data['revisions'][0]['git_repository_url']= r_git_repository_url
    data['revisions'][0]['git_repository_branch']= r_git_repository_branch
    data['revisions'][0]['contacts']= r_contacts
    data['revisions'][0]['patch_mboxes']= r_patch_mboxes
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



r_log_url="test"

print(str(base_kernel_hash) + "+" + str(patchset_hash))
#revisions variable
r_id=str(base_kernel_hash) + "+" + str(patchset_hash)
r_origin="gkernelci"
r_git_repository_url="git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"
r_git_repository_branch=kernel_version
r_contacts=["Mike Pagano <mpagano@gentoo.org>","Alice Ferrazzi <alicef@gentoo.org>"]
r_patch_mboxes=get_patches_list()
r_log_url="https://kernel-ci.emjay-embedded.co.uk/api/v2/logs/16852/raw"
r_valid=args.result

#builds variable
b_id="gkernelci:50-6"
b_origin="gkernelci"
b_revision_id=r_id
b_architecture=args.arch
b_log_url="https://kernel-ci.emjay-embedded.co.uk/api/v2/logs/16853/raw"
b_valid=args.result
b_misc_url="https://kernel-ci.emjay-embedded.co.uk/#/builders/50/builds/5"


create_object(r_id, r_origin, r_git_repository_url, r_git_repository_branch, 
              r_contacts, r_patch_mboxes, r_log_url, r_valid, b_id, b_origin,
              b_revision_id, b_architecture, b_log_url, b_valid, b_misc_url)

