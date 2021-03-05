# arch status
<table>
<tr>
	<td>
Gentoo ARCH
	</td>
	<td>
defconfig
	</td>
	<td>
boards to test
	</td>
	<td>
	notes
	</td>
</tr>

<tr>
<td>
ARM
</td>
	<td>
	multi_v7_defconfig
	</td>
	<td>
	qemu(virt-2.11)
	</td>
</tr>

<tr>
<td>
ARM64
</td>
	<td>
	arm64_defconfig
	</td>
	<td>
	qemu(virt)
	</td>
</tr>

<tr>
<td>
alpha
</td>
	<td>
	defconfig
	</td>
	<td>
	qemu(clipper)
	</td>
	<td>
	defconfig miss CONFIGs
	</td>
</tr>

<tr>
<td>
hppa/parisc
</td>
	<td>
	generic-32bit_defconfig
	</td>
	<td>
	qemu(hppa)
	</td>
	<td>
	LAVA need a patch https://git.lavasoftware.org/lava/lava/-/merge_requests/1419
	Merged, will be in 2021.[2-x]
	</td>
</tr>

<tr>
<td>
m68k
</td>
	<td>
	mac_defconfig
	</td>
	<td>
	qemu(q800)
	</td>
	<td>
	LAVA need a patch
	https://git.lavasoftware.org/lava/lava/-/merge_requests/1424
	Merged, will be in 2021.[2-x]
	</td>
</tr>

<tr>
<td>
MIPS32
</td>
	<td>
	malta_kvm_guest_defconfig
	</td>
	<td>
	qemu(malta)
	</td>
</tr>

<tr>
<td>
PPC
</td>
	<td>
	pmac32_defconfig
	</td>
	<td>
	qemu(g3beige)
	</td>
	<td>
	Need CONFIGs
	</td>
</tr>

<tr>
<td>
PPC64
</td>
	<td>
	pseries_defconfig
	</td>
	<td>
	qemu(pseries)
	</td>
</tr>

<tr>
<td>
riscv
</td>
	<td>
	defconfig
	</td>
	<td>
	qemu(virt)
	</td>
	<td>
	Need qemu > x (at least buster is too old)
	</td>
</tr>

<tr>
<td>
sparc64
</td>
	<td>
	sparc64_defconfig
	</td>
	<td>
	qemu(sun4u)
	</td>
	<td>
	defconfig miss CONFIGs
	</td>
</tr>

<tr>
<td>
x86
</td>
	<td>
	i386_defconfig
	</td>
	<td>
	qemu(pc)
	</td>
</tr>

<tr>
<td>
x86_64
</td>
	<td>
	x86_64_defconfig
	</td>
	<td>
	qemu(pc)
	</td>
</tr>
</table>

Note: ia64 is not boot-testable due to lack of qemu hardware


Constraints:
============
* Each arch could be compiled by more than one toolchain
* Each arch could have more than 1 defconfig
* Each board could be booted by more than 1 defconfig
* earch defconfig could boot more than 1 board
* Filtering board by arch is not a correct way (example lot of ppc boards work with only a subset of ppc defconfigs.)
* So the only viable way to find board to boot is to filter per defconfig or better per CONFIG_ (permiting to use randconfig)

Example: qemu-cubieboard could be booted by
* arm/multi_v7_defconfig/gcc
* arm/multi_v7_defconfig/clang
* arm/sunxi_defconfig/gcc
* arm/sunxi_defconfig/clang

So a proposition is to:
=======================
First stage (build)
-------------------
- Each arch should have a list of defconfig to build
- Each defconfig could have a list of CONFIG fixups
- Each arch should have a list of toolchains to use (gcc vs clang for example)
- each build could be identified by its directory source/arch/defconfig/toolchain

Second stage (generate boot job)
--------------------------------
- each board should have a list of CONFIG necessary to boot them (mostly CONFIG_ARCH_XXXX)
- For each build, compare the final .config and generate jobs for each matching board.

Third stage (send jobs to LAVA labs)
------------------------------------
- A list for lava labs must exists with an user/token.
- the user must not be staff/admin of the lab
- For each lab check device-types availlable and the state of related board (must be Good)

rootfs
------
TODO: Different rootfs could be booted
* "classic" multilib
* hardened (SELinux)
* openRC vs systemd

Tests
-----
* Gentoo specifics
* general tests
	* kselftest

Implementation details
======================
Compiling with a native toolchain
---------------------------------
Goal: Compiling kernel using official stage3.

For x86_64, it is easy since no cross-compilation is needed.
But for other arches, we cannot use stage3 as-is.
Using a worker of the same arch for each arch is not a good solution since lot of arches
will be either too slow or hard to find.

So the solution is to use qemu-user-static.
On x86_64, using qemu-user-static imply no performance loss, so we can handle all arches the same way.

With qemu-user-static we can chroot in a stage3, and compile kernel using the toolchain present in it.
We just need to "mount" sources and output directory in this stage3.

The original stage3 needs some modification:
- It need a buildbot user with the same id than the worker.
- It need bc and libelf

Emerging bc/libelf via qemu-user is long, so we use a binary package cache in a volume.
But even with binpkg, it took too many time, so the final stage3 must be cached, so that we have to
do nothing when we need it.
