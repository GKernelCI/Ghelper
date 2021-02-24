#!/usr/bin/env python3

"""
    boot a gentoo artifact directory
"""

import argparse
import hashlib
import os
import re
import subprocess
import sys
import time
import xmlrpc.client
import yaml
import jinja2


###############################################################################
###############################################################################
def boot():
    if not os.path.exists("%s/config" % kdir):
        print("ERROR: no config in %s" % kdir)
        return 1
    kconfig = open("%s/config" % kdir)
    kconfigs = kconfig.read()
    kconfig.close()
    if re.search("CONFIG_ARM=", kconfigs):
        arch = "arm"
        qarch = "arm"
        larch = "arm"
    if re.search("CONFIG_ARM64=", kconfigs):
        arch = "arm64"
        qarch = "aarch64"
        larch = "arm64"
    if re.search("CONFIG_PPC64=", kconfigs):
        arch = "powerpc64"
        qarch = "ppc64"
        larch = "powerpc"
    if re.search("CONFIG_SPARC32=", kconfigs):
        arch = "sparc"
        qarch = "sparc"
        larch = "sparc"
    if re.search("CONFIG_SPARC64=", kconfigs):
        arch = "sparc64"
        qarch = "sparc64"
        larch = "sparc"
    if re.search("CONFIG_X86_64=", kconfigs):
        arch = "x86_64"
        qarch = "x86_64"
        larch = "x86_64"
    if re.search("CONFIG_X86=", kconfigs) and not re.search("CONFIG_X86_64=", kconfigs):
        arch = "x86"
        qarch = "i386"
        larch = "x86"

    print("INFO: arch is %s, Linux arch is %s, QEMU arch is %s" % (arch, larch, qarch))

    for device in t["templates"]:
        if "devicename" in device:
            devicename = device["devicename"]
        else:
            devicename = device["devicetype"]
        if "larch" in device:
            device_larch = device["larch"]
        else:
            device_larch = device["arch"]
        if device_larch != larch:
            if args.debug:
                print("SKIP: %s (wrong larch %s vs %s)" % (devicename, device_larch, larch))
            continue
        if device["arch"] != arch:
            if args.debug:
                print("SKIP: %s device arch: %s vs arch=%s" % (devicename, device["arch"], arch))
            continue
        print("==============================================")
        print("CHECK: %s" % devicename)
        # check needed files
        if "kernelfile" not in device:
            print("ERROR: missing kernelfile")
            continue
        kerneltype = "image"
        kfile = "%s/%s" % (kdir, device["kernelfile"])
        if os.path.isfile(kfile):
            if args.debug:
                print("DEBUG: found %s" % kfile)
        else:
            print("SKIP: no kernelfile %s in %s" % (device["kernelfile"], kdir))
            continue
        # Fill lab indepedant data
        jobdict = {}
        jobdict["KERNELFILE"] = device["kernelfile"]
        with open(kfile, "rb") as fkernel:
            jobdict["KERNEL_SHA256"] = hashlib.sha256(fkernel.read()).hexdigest()
        jobdict["DEVICETYPE"] = device["devicetype"]
        jobdict["MACH"] = device["mach"]
        jobdict["ARCH"] = device["arch"]
        jobdict["KERNELTYPE"] = kerneltype
        jobdict["PATH"] = relpath

        if "console_device" in device:
            jobdict["console_device"] = device["console_device"]

        if "qemu" in device:
            if qarch == "unsupported":
                print("Qemu does not support this")
                continue
            print("\tQEMU")
            jobdict["qemu_arch"] = qarch
            if "netdevice" in device["qemu"]:
                jobdict["qemu_netdevice"] = device["qemu"]["netdevice"]
            if "model" in device["qemu"]:
                jobdict["qemu_model"] = device["qemu"]["model"]
            if "no_kvm" in device["qemu"]:
                jobdict["qemu_no_kvm"] = device["qemu"]["no_kvm"]
            if "machine" in device["qemu"]:
                jobdict["qemu_machine"] = device["qemu"]["machine"]
            if "cpu" in device["qemu"]:
                jobdict["qemu_cpu"] = device["qemu"]["cpu"]
            if "memory" in device["qemu"]:
                jobdict["qemu_memory"] = device["qemu"]["memory"]
            if "console_device" in device["qemu"]:
                jobdict["console_device"] = device["qemu"]["console_device"]
            if "guestfs_interface" in device["qemu"]:
                jobdict["guestfs_interface"] = device["qemu"]["guestfs_interface"]
            if "guestfs_driveid" in device["qemu"]:
                jobdict["guestfs_driveid"] = device["qemu"]["guestfs_driveid"]
            if "extra_options" in device["qemu"]:
                jobdict["qemu_extra_options"] = device["qemu"]["extra_options"]
            if "extra_options" not in device["qemu"]:
                jobdict["qemu_extra_options"] = []
            if "smp" in device["qemu"]:
                jobdict["qemu_extra_options"].append("-smp cpus=%d" % device["qemu"]["smp"])
            netoptions = "ip=dhcp"
            jobdict["qemu_extra_options"].append("-append '%s %s'" % (device["qemu"]["append"], netoptions))
        templateLoader = jinja2.FileSystemLoader(searchpath=templatedir)
        templateEnv = jinja2.Environment(loader=templateLoader)
        template = templateEnv.get_template("gentoo.jinja2")

        # now try to boot on LAVA
        for lab in tlabs["labs"]:
            send_to_lab = False
            print("\tCheck %s on %s" % (devicename, lab["name"]))
            server = xmlrpc.client.ServerProxy(lab["lavauri"])
            devlist = server.scheduler.devices.list()
            # TODO check device state
            for labdevice in devlist:
                if labdevice["type"] == device["devicetype"]:
                    send_to_lab = True
            if not send_to_lab:
                print("\tSKIP: not found")
                continue
            if "dtb" in device:
                jobdict["DTB"] = device["dtb"]
                dtbfile = "%s/%s" % (kdir, device["dtb"])
                if not os.path.isfile(dtbfile):
                    print("SKIP: no dtb at %s" % dtbfile)
                    continue
                with open(dtbfile, "rb") as fdtb:
                    jobdict["DTB_SHA256"] = hashlib.sha256(fdtb.read()).hexdigest()
            if re.search("CONFIG_MODULES=y", kconfigs):
                with open("%s/modules.tar.gz" % kdir, "rb") as fmodules:
                    jobdict["MODULES_SHA256"] = hashlib.sha256(fmodules.read()).hexdigest()

            jobdict["BOOT_FQDN"] = args.fileserverfqdn
            result = subprocess.check_output("./gentoo_get_stage_url.sh --arch %s" % arch, shell=True)
            for line in result.decode("utf-8").split("\n"):
                what = line.split("=")
                if what[0] == 'ROOTFS_PATH':
                    jobdict["rootfs_path"] = what[1]
                if what[0] == 'ROOTFS_BASE':
                    jobdict["ROOT_FQDN"] = what[1]
                if what[0] == 'ROOTFS_SHA512':
                    jobdict["rootfs_sha512"] = what[1]
                if what[0] == 'PORTAGE_URL':
                    jobdict["portage_url"] = what[1]
            jobdict["auto_login_password"] = 'bob'

            if re.search("gz$", jobdict["rootfs_path"]):
                jobdict["ROOTFS_COMP"] = "gz"
            if re.search("xz$", jobdict["rootfs_path"]):
                jobdict["ROOTFS_COMP"] = "xz"
            if re.search("bz2$", jobdict["rootfs_path"]):
                jobdict["ROOTFS_COMP"] = "bz2"

            jobdict["JOBNAME"] = "Gentoo test %s %s %s %s %s on %s" % (args.buildname, args.buildnumber, args.arch, args.defconfig, args.toolchain, devicename)
            jobt = template.render(jobdict)
            if not args.noact:
                jobid = server.scheduler.jobs.submit(jobt)
                publicuri = re.sub("//.*@", "//", lab["lavauri"])
                publicuri = re.sub("/RPC2", "", publicuri)
                joburl = "%s/scheduler/job/%s" % (publicuri, jobid)
                print("Submited as %s on %s %s" % (jobid, lab["name"], joburl))
                if lab["name"] not in boots:
                    boots[lab["name"]] = {}
                boots[lab["name"]][jobid] = {}
                boots[lab["name"]][jobid]["devicename"] = devicename
            else:
                print("\tSKIP: send job to %s" % lab["name"])
    return 0

###############################################################################
###############################################################################

boots = {}
templatedir = os.getcwd()
dtemplates_yaml = "all.yaml"

os.environ["LC_ALL"] = "C"
os.environ["LC_MESSAGES"] = "C"
os.environ["LANG"] = "C"

parser = argparse.ArgumentParser()
parser.add_argument("--noact", "-n", help="No act", action="store_true")
parser.add_argument("--quiet", "-q", help="Quiet, do not print build log", action="store_true")
parser.add_argument("--debug", "-d", help="increase debug level", action="store_true")
parser.add_argument("--waitforjobsend", "-W", help="Wait until all jobs ended", action="store_true")
parser.add_argument("--arch", type=str, help="Gentoo arch", required=True)
parser.add_argument("--buildname", type=str, help="buildbot build name", required=True)
parser.add_argument("--buildnumber", type=str, help="buildbot buildnumber", required=True)
parser.add_argument("--defconfig", type=str, help="The defconfig name", required=True)
parser.add_argument("--toolchain", type=str, help="The toolchain name", required=True)
parser.add_argument("--fileserver", type=str, help="The fileserver basepath", required=True)
parser.add_argument("--fileserverfqdn", type=str, help="An URL to the base fileserver", required=True)
args = parser.parse_args()

try:
    tfile = open(dtemplates_yaml)
except IOError:
    print("ERROR: Cannot open device template config file: %s" % dtemplates_yaml)
    sys.exit(1)
t = yaml.safe_load(tfile)

# TODO temp hack to generate a labs.yaml from lavacli identities
# This will be replaced later
config_dir = os.environ.get("XDG_CONFIG_HOME", "~/.config")
config_filename = os.path.expanduser(os.path.join(config_dir, "lavacli.yaml"))
try:
    f_conf = open(config_filename, "r", encoding="utf-8")
    data = yaml.safe_load(f_conf.read())
except IOError:
    print("Fail to open %s" % config_filename)
    sys.exit(1)
tlabs = {}
tlabs["labs"] = []
tlab = {}
tlab["name"] = "Gentoo"
tlab["lavauri"] = data["buildbot"]["uri"]
tlabs["labs"].append(tlab)

relpath = "%s/%s/%s/%s/%s" % (args.buildname, args.arch, args.buildnumber, args.defconfig, args.toolchain)
kdir = "%s/%s" % (args.fileserver, relpath)

ret = boot()
if ret != 0:
    sys.exit(1)

# We should have generated at least one job
if len(boots) == 0 and not args.noact:
    sys.exit(1)

def dump_log(jobid, labname, server):
    # save logs
    logdir = "%s/logs" % kdir
    if not os.path.isdir(logdir):
        os.mkdir(logdir)
    lablogdir = "%s/%s" % (logdir, labname)
    if not os.path.isdir(lablogdir):
        os.mkdir(lablogdir)
    fd = open("%s/%s.log.txt" % (lablogdir, jobid), 'w')
    try:
        r = server.scheduler.job_output(jobid)
    except xmlrpc.client.Fault:
        return 1
    logs = yaml.unsafe_load(r.data)
    for line in logs:
        for msg in line["msg"]:
            fd.write(msg)
        fd.write("\n")
    fd.close()
    return 0

# return true if all tests are ok (or their fail acknowledged via skiplist)
# return false if any tests failed (without being skiped)
def check_tests(jobid, labname, server):
    result = True
    testjob_results_raw = server.results.get_testjob_results_yaml(jobid)
    testjob_results = yaml.unsafe_load(testjob_results_raw)
    # save logs
    logdir = "%s/logs" % kdir
    if not os.path.isdir(logdir):
        os.mkdir(logdir)
    lablogdir = "%s/%s" % (logdir, labname)
    if not os.path.isdir(lablogdir):
        os.mkdir(lablogdir)
    flog = open("%s/%s.testjob_results.raw" % (lablogdir, jobid), "w")
    flog.write(testjob_results_raw)
    flog.close()
    for test in testjob_results:
        print("CHECK: SUITE: %s NAME: %s RESULT: %s" % (test["suite"], test["name"], test["result"]))
        if test["result"] == 'fail':
            skipfile = "skip/%s" % re.sub("^[0-9]*_", "", test["suite"])
            try:
                if args.debug:
                    print("DEBUG: found %s" % skipfile)
                fs = open(skipfile, 'r')
                if re.search("(\n|^)%s(\n|$)" % test["name"], fs.read()):
                    print("INFO: found in %s" % skipfile)
                else:
                    print("INFO: not found in %s" % skipfile)
                    result = False
                fs.close()
            except IOError:
                if args.debug:
                    print("DEBUG: skiplist %s not found" % skipfile)
                result = False
        else:
            if args.debug:
                print("DEBUG test ok")
    return result

if len(boots) > 0 and args.waitforjobsend:
    all_jobs_ended = False
    all_jobs_success = True
    while not all_jobs_ended:
        time.sleep(60)
        all_jobs_ended = True
        for labname in boots:
            for lab in tlabs["labs"]:
                if lab["name"] == labname:
                    break;
            #print("DEBUG: Check %s with %s" % (labname, lab["lavauri"]))
            server = xmlrpc.client.ServerProxy(lab["lavauri"], allow_none=True)
            for jobid in boots[labname]:
                try:
                    jobd = server.scheduler.jobs.show(jobid)
                    if jobd["state"] != 'Finished':
                        all_jobs_ended = False
                        print("Wait for job %d" % jobid)
                        print(jobd)
                    else:
                        dump_log(jobid, labname, server)
                        boots[labname][jobid]["health"] = jobd["health"]
                        boots[labname][jobid]["state"] = jobd["state"]
                        if jobd["health"] != 'Complete':
                            all_jobs_success = False
                        else:
                            all_jobs_success = check_tests(jobid, labname, server)
                except OSError as e:
                    print(e)
                except TimeoutError as e:
                    print(e)
    if not all_jobs_success:
        sys.exit(1)

print(boots)

sys.exit(0)
