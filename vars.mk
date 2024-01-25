#
# toolchain-arm-linux-gnu/vars.mk
#

# -----------------------------------------------------------------------
# flags
#
MAKEFLAGS = -j1

# -----------------------------------------------------------------------
# triplets
#
TARGET = arm-linux-gnu
# In the process of building the cross-compilation toolchain a local toolchain is also created.
# To avoid confusion with any existing native compilation tools the "triplet" for this toolchain
# has the word "cross" embedded into it.
HOST = $(shell bash -c 'echo $$MACHTYPE' | sed 's/-[^-]*/-cross/')

# -----------------------------------------------------------------------
#
# directories
#

# Do not change CLFS and CROSSTOOLS location if you plan to release the resulting toolchain
CLFS = /opt/$(TARGET)/clfs
CROSSTOOLS = /opt/$(TARGET)/crosstools
WORK = $(shell pwd)/work

# -----------------------------------------------------------------------
#
# versions
#
# Use kernel 3.x version to provide support for input events
# For example, EVIOCGPROP definition was added in 3.x and its required for tslib
KERNEL_HEADERS_VERSION = 3.1.10
LIBGMP_VERSION = 6.3.0
LIBMPFR_VERSION = 4.2.1
LIBMPC_VERSION = 1.3.1
BINUTILS_VERSION = 2.23.2
# Use version 4.3 since glibc won't build with recent GNU Make (4.4 or above)
MAKE_VERSION = 4.3
# This is the last version released before dropping support for ARMv4 devices
GLIBC_VERSION = 2.11.3
GLIBC_PORTS_VERSION = 2.11
# This is the last version released before dropping support for ARMv4 devices
GCC_VERSION = 4.7.4

# End of file
