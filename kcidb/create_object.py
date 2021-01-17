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

r_id = str(base_kernel_hash) + "+" + str(patchset_hash)
print(r_id)

data = dict(
    version=dict(
        major=3,
        minor=0
    ),
    revisions=[
        dict(
            id=r_id,
            origin="gkernelci",
            git_repository_url="git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git",
            git_repository_branch=kernel_version,
            contacts=[
                "Mike Pagano <mpagano@gentoo.org>",
                "Alice Ferrazzi <alicef@gentoo.org>"
            ],
            patch_mboxes=get_patches_list(),
            log_url="https://kernel-ci.emjay-embedded.co.uk/api/v2/logs/16852/raw",
            valid=args.result,
        ),
    ],
    builds=[
        dict(
            id="gkernelci:50-6",
            origin="gkernelci",
            revision_id=r_id,
            architecture=args.arch,
            log_url="https://kernel-ci.emjay-embedded.co.uk/api/v2/logs/16853/raw",
            valid=args.result,
            misc=dict(
                url="https://kernel-ci.emjay-embedded.co.uk/#/builders/50/builds/5",
            ),
        ),
    ]
)

with open("data_file.json", "w") as write_file:
    json.dump(data, write_file)
