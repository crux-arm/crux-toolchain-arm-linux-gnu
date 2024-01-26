# -----------------------------------------------------------------------
#
# toolchain-arm-linux-gnu/Makefile
#


CURL_CMD = curl -sSL --retry 5 --retry-max-time 60

ifneq ("$(wildcard vars.mk)", "")
include vars.mk
endif

all: linux-headers libgmp libmpfr libmpc binutils gcc-static make glibc gcc-final test

.PHONY: clean
clean: \
	linux-headers-clean \
	libgmp-clean \
	libmpfr-clean \
	libmpc-clean \
	binutils-clean \
	gcc-static-clean \
	make-clean \
	glibc-clean \
	gcc-final-clean \
	test-clean

.PHONY: distclean
distclean: \
	clean \
	linux-headers-distclean \
	libgmp-distclean \
	libmpfr-distclean \
	libmpc-distclean \
	binutils-distclean \
	gcc-static-distclean \
	make-distclean \
	glibc-distclean \
	gcc-final-distclean \
	test-distclean

.PHONY: download
download: \
	$(WORK)/linux-$(KERNEL_HEADERS_VERSION).tar.bz2 \
	$(WORK)/gmp-$(LIBGMP_VERSION).tar.xz \
	$(WORK)/mpfr-$(LIBMPFR_VERSION).tar.xz \
	$(WORK)/mpc-$(LIBMPC_VERSION).tar.gz \
	$(WORK)/binutils-$(BINUTILS_VERSION).tar.bz2 \
	$(WORK)/gcc-$(GCC_VERSION).tar.bz2 \
	$(WORK)/glibc-$(GLIBC_VERSION).tar.bz2 \
	$(WORK)/glibc-ports-$(GLIBC_PORTS_VERSION).tar.bz2

# -----------------------------------------------------------------------
#
# linux-headers
#

$(WORK)/linux-$(KERNEL_HEADERS_VERSION).tar.bz2:
	$(CURL_CMD) -o $(WORK)/linux-$(KERNEL_HEADERS_VERSION).tar.bz2 \
		https://mirrors.edge.kernel.org/pub/linux/kernel/v3.x/linux-$(KERNEL_HEADERS_VERSION).tar.bz2

$(WORK)/linux-$(KERNEL_HEADERS_VERSION): $(WORK)/linux-$(KERNEL_HEADERS_VERSION).tar.bz2
	tar -C $(WORK) -xvf $(WORK)/linux-$(KERNEL_HEADERS_VERSION).tar.bz2
	touch $(WORK)/linux-$(KERNEL_HEADERS_VERSION)

$(CLFS)/usr/include/asm: $(WORK)/linux-$(KERNEL_HEADERS_VERSION)
	@echo "[`date +'%F %T'`] Building linux-headers"
	mkdir -p $(CLFS)/usr/include
	cd $(WORK)/linux-$(KERNEL_HEADERS_VERSION) && \
		make mrproper && \
		make ARCH=arm headers_check && \
		make ARCH=arm INSTALL_HDR_PATH=$(CLFS)/usr headers_install
	touch $(CLFS)/usr/include/asm

.PHONY: linux-headers
linux-headers: $(CLFS)/usr/include/asm

.PHONY: linux-headers-clean
linux-headers-clean:
	rm -vrf $(WORK)/linux-$(KERNEL_HEADERS_VERSION)

.PHONY: linux-headers-distclean
linux-headers-distclean: linux-headers-clean
	rm -vf $(WORK)/linux-$(KERNEL_HEADERS_VERSION).tar.bz2

# -----------------------------------------------------------------------
#
# libgmp
#

$(WORK)/gmp-$(LIBGMP_VERSION).tar.xz:
	$(CURL_CMD) -o $(WORK)/gmp-$(LIBGMP_VERSION).tar.xz \
		https://ftp.gnu.org/gnu/gmp/gmp-$(LIBGMP_VERSION).tar.xz

$(WORK)/gmp-$(LIBGMP_VERSION): $(WORK)/gmp-$(LIBGMP_VERSION).tar.xz
	tar -C $(WORK) -xvf $(WORK)/gmp-$(LIBGMP_VERSION).tar.xz
	touch $(WORK)/gmp-$(LIBGMP_VERSION)

$(WORK)/build-libgmp: $(WORK)/gmp-$(LIBGMP_VERSION)
	mkdir -p $(WORK)/build-libgmp
	touch $(WORK)/build-libgmp

$(CROSSTOOLS)/lib/libgmp.so: $(WORK)/build-libgmp
	@echo "[`date +'%F %T'`] Building libgmp"
	cd $(WORK)/build-libgmp && \
		unset CFLAGS && \
		unset CXXFLAGS && \
		CPPFLAGS=-fexceptions \
		$(WORK)/gmp-$(LIBGMP_VERSION)/configure \
			--build=$(HOST) \
			--prefix=$(CROSSTOOLS) && \
		make && \
		make install && \
		rm -rf $(CROSSTOOLS)/share
	touch $(CROSSTOOLS)/lib/libgmp.so

.PHONY: libgmp
libgmp: $(CROSSTOOLS)/lib/libgmp.so

.PHONY: libgmp-clean
libgmp-clean:
	rm -vrf $(WORK)/build-libgmp $(WORK)/gmp-$(LIBGMP_VERSION)

.PHONY: libgmp-distclean
libgmp-distclean: libgmp-clean
	rm -vrf $(WORK)/gmp-$(LIBGMP_VERSION).tar.xz

# -----------------------------------------------------------------------
#
# libmpfr
#

$(WORK)/mpfr-$(LIBMPFR_VERSION).tar.xz:
	$(CURL_CMD) -o $(WORK)/mpfr-$(LIBMPFR_VERSION).tar.xz \
		https://ftp.gnu.org/gnu/mpfr/mpfr-$(LIBMPFR_VERSION).tar.xz

$(WORK)/mpfr-$(LIBMPFR_VERSION): $(WORK)/mpfr-$(LIBMPFR_VERSION).tar.xz
	tar -C $(WORK) -xvf $(WORK)/mpfr-$(LIBMPFR_VERSION).tar.xz
	touch $(WORK)/mpfr-$(LIBMPFR_VERSION)

$(WORK)/build-libmpfr: $(WORK)/mpfr-$(LIBMPFR_VERSION)
	mkdir -p $(WORK)/build-libmpfr
	touch $(WORK)/build-libmpfr

$(CROSSTOOLS)/lib/libmpfr.so: $(WORK)/build-libmpfr
	@echo "[`date +'%F %T'`] Building libmpfr"
	cd $(WORK)/build-libmpfr && \
		unset CFLAGS && \
		unset CXXFLAGS && \
		LDFLAGS="-Wl,-rpath,$(CROSSTOOLS)/lib" && \
		$(WORK)/mpfr-$(LIBMPFR_VERSION)/configure \
			--prefix=$(CROSSTOOLS) \
			--enable-shared \
			--with-gmp=$(CROSSTOOLS) && \
		make && \
		make install && \
		rm -rf $(CROSSTOOLS)/share
	touch $(CROSSTOOLS)/lib/libmpfr.so

.PHONY: libmpfr
libmpfr: libgmp $(CROSSTOOLS)/lib/libmpfr.so

.PHONY: libmpfr-clean
libmpfr-clean:
	rm -vrf $(WORK)/build-libmpfr $(WORK)/mpfr-$(LIBMPFR_VERSION)

.PHONY: libmpfr-distclean
libmpfr-distclean: libmpfr-clean
	rm -vrf $(WORK)/mpfr-$(LIBMPFR_VERSION).tar.xz

# -----------------------------------------------------------------------
#
# libmpc
#

$(WORK)/mpc-$(LIBMPC_VERSION).tar.gz:
	$(CURL_CMD) -o $(WORK)/mpc-$(LIBMPC_VERSION).tar.gz \
		https://ftp.gnu.org/gnu/mpc/mpc-$(LIBMPC_VERSION).tar.gz

$(WORK)/mpc-$(LIBMPC_VERSION): $(WORK)/mpc-$(LIBMPC_VERSION).tar.gz
	tar -C $(WORK) -xvf $(WORK)/mpc-$(LIBMPC_VERSION).tar.gz
	touch $(WORK)/mpc-$(LIBMPC_VERSION)

$(WORK)/build-libmpc: $(WORK)/mpc-$(LIBMPC_VERSION)
	mkdir -p $(WORK)/build-libmpc
	touch $(WORK)/build-libmpc

$(CROSSTOOLS)/lib/libmpc.so: $(WORK)/build-libmpc
	@echo "[`date +'%F %T'`] Building libmpc"
	cd $(WORK)/build-libmpc && \
		unset CFLAGS && \
		unset CXXFLAGS && \
		LDFLAGS="-Wl,-rpath,$(CROSSTOOLS)/lib" && \
		$(WORK)/mpc-$(LIBMPC_VERSION)/configure \
			--prefix=$(CROSSTOOLS) \
			--with-gmp=$(CROSSTOOLS) \
			--with-mpfr=$(CROSSTOOLS) && \
		make && \
		make install
	touch $(CROSSTOOLS)/lib/libmpc.so

.PHONY: libmpc
libmpc: libmpfr $(CROSSTOOLS)/lib/libmpc.so

.PHONY: libmpc-clean
libmpc-clean:
	rm -vrf $(WORK)/build-libmpc $(WORK)/mpc-$(LIBMPC_VERSION)

.PHONY: libmpc-distclean
libmpc-distclean: libmpc-clean
	rm -vrf $(WORK)/mpc-$(LIBMPC_VERSION).tar.gz


# -----------------------------------------------------------------------
#
# binutils
#

$(WORK)/binutils-$(BINUTILS_VERSION).tar.bz2:
	$(CURL_CMD) -o $(WORK)/binutils-$(BINUTILS_VERSION).tar.bz2 \
		https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.bz2

$(WORK)/binutils-$(BINUTILS_VERSION): $(WORK)/binutils-$(BINUTILS_VERSION).tar.bz2
	tar -C $(WORK) -xvf $(WORK)/binutils-$(BINUTILS_VERSION).tar.bz2
	sed -i '/^SUBDIRS/s/doc//' $(WORK)/binutils-$(BINUTILS_VERSION)/*/Makefile.in
	touch $(WORK)/binutils-$(BINUTILS_VERSION)

$(WORK)/build-binutils: $(WORK)/binutils-$(BINUTILS_VERSION)
	mkdir -p $(WORK)/build-binutils
	touch $(WORK)/build-binutils

$(CLFS)/usr/include/libiberty.h: $(WORK)/build-binutils
	@echo "[`date +'%F %T'`] Building binutils"
	cd $(WORK)/build-binutils && \
		unset CFLAGS && \
		unset CXXFLAGS && \
		AR=ar \
		AS=as \
		$(WORK)/binutils-$(BINUTILS_VERSION)/configure \
			--target=$(TARGET) \
			--prefix=$(CROSSTOOLS) \
			--with-sysroot=$(CLFS) \
			--enable-shared \
			--nfp \
			--disable-nls \
			--disable-multilib \
			--disable-werror && \
		make configure-host && \
		make && \
		make install && \
		rm -rf $(CROSSTOOLS)/share
	cp -va $(WORK)/binutils-$(BINUTILS_VERSION)/include/libiberty.h $(CLFS)/usr/include
	touch $(CLFS)/usr/include/libiberty.h

.PHONY: binutils
binutils: linux-headers $(CLFS)/usr/include/libiberty.h

.PHONY: binutils-clean
binutils-clean:
	rm -vrf $(WORK)/build-binutils $(WORK)/binutils-$(BINUTILS_VERSION)

.PHONY: binutils-distclean
binutils-distclean: binutils-clean
	rm -f $(WORK)/binutils-$(BINUTILS_VERSION).tar.bz2

# -----------------------------------------------------------------------
#
# gcc-static
#

$(WORK)/gcc-$(GCC_VERSION).tar.bz2:
	$(CURL_CMD) -o $(WORK)/gcc-$(GCC_VERSION).tar.bz2 \
		https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.bz2

$(WORK)/gcc-$(GCC_VERSION): $(WORK)/gcc-$(GCC_VERSION).tar.bz2
	tar -C $(WORK) -xvf $(WORK)/gcc-$(GCC_VERSION).tar.bz2
	sed -i 's|REVISION|REVISION " (CRUX-ARM)"|' $(WORK)/gcc-$(GCC_VERSION)/gcc/version.c
	touch $(WORK)/gcc-$(GCC_VERSION)

$(WORK)/build-gcc-static: $(WORK)/gcc-$(GCC_VERSION)
	mkdir -p $(WORK)/build-gcc-static
	touch $(WORK)/build-gcc-static

$(CROSSTOOLS)/lib/gcc: $(WORK)/build-gcc-static $(WORK)/gcc-$(GCC_VERSION)
	@echo "[`date +'%F %T'`] Building gcc-static"
	cd $(WORK)/build-gcc-static && \
		unset CXXFLAGS && \
		CFLAGS='-fgnu89-inline' \
		AR=ar \
		LDFLAGS="-Wl,-rpath,$(CROSSTOOLS)/lib" \
		$(WORK)/gcc-$(GCC_VERSION)/configure \
			--build=$(HOST) \
			--host=$(HOST) \
			--target=$(TARGET) \
			--prefix=$(CROSSTOOLS) \
			--libexecdir=$(CROSSTOOLS)/lib \
			--with-sysroot=$(CLFS) \
			--with-gmp=$(CROSSTOOLS) \
			--with-mpfr=$(CROSSTOOLS) \
			--with-mpc=$(CROSSTOOLS) \
			--with-newlib \
			--without-headers \
			--disable-multilib \
			--disable-nls \
			--disable-decimal-float \
			--disable-libgomp \
			--disable-libmudflap \
			--disable-libssp \
			--disable-shared \
			--disable-threads \
			--enable-languages=c,c++ \
			--enable-obsolete && \
		make all-gcc all-target-libgcc && \
		make install-gcc install-target-libgcc
	touch $(CROSSTOOLS)/lib/gcc

.PHONY: gcc-static
gcc-static: linux-headers libgmp libmpfr libmpc binutils $(CROSSTOOLS)/lib/gcc

.PHONY: gcc-static-clean
gcc-static-clean:
	rm -vrf $(WORK)/build-gcc-static $(WORK)/gcc-$(GCC_VERSION)

.PHONY: gcc-static-distclean
gcc-static-distclean: gcc-static-clean
	rm -vf $(WORK)/gcc-$(GCC_VERSION).tar.bz2

# -----------------------------------------------------------------------
#
# make
#

$(WORK)/make-$(MAKE_VERSION).tar.gz:
	$(CURL_CMD) -o $(WORK)/make-$(MAKE_VERSION).tar.gz \
		https://ftp.gnu.org/gnu/make/make-$(MAKE_VERSION).tar.gz

$(WORK)/make-$(MAKE_VERSION): $(WORK)/make-$(MAKE_VERSION).tar.gz
	tar -C $(WORK) -xvf $(WORK)/make-$(MAKE_VERSION).tar.gz
	touch $(WORK)/make-$(MAKE_VERSION)

$(WORK)/build-make: $(WORK)/make-$(MAKE_VERSION)
	mkdir -p $(WORK)/build-make
	touch $(WORK)/build-make

$(CROSSTOOLS)/bin/make: $(WORK)/build-make
	@echo "[`date +'%F %T'`] Building make"
	cd $(WORK)/build-make && \
		export PATH=$(CROSSTOOLS)/bin:$$PATH && \
		$(WORK)/make-$(MAKE_VERSION)/configure \
			--prefix=/usr && \
		make && \
		install -D -m 0755 make $(CROSSTOOLS)/bin/make
	touch $(CROSSTOOLS)/bin/make

.PHONY: make
make: $(CROSSTOOLS)/bin/make

.PHONY: make-clean
make-clean:
	rm -vrf $(WORK)/build-make

.PHONY: make-distclean
make-distclean:
	rm -vf $(WORK)/make-$(MAKE_VERSION).tar.gz

# -----------------------------------------------------------------------
#
# glibc
#

$(WORK)/glibc-$(GLIBC_VERSION).tar.bz2:
	$(CURL_CMD) -o $(WORK)/glibc-$(GLIBC_VERSION).tar.bz2  \
		https://ftp.gnu.org/gnu/glibc/glibc-$(GLIBC_VERSION).tar.bz2

$(WORK)/glibc-ports-$(GLIBC_PORTS_VERSION).tar.bz2:
	$(CURL_CMD) -o $(WORK)/glibc-ports-$(GLIBC_PORTS_VERSION).tar.bz2 \
		https://ftp.gnu.org/gnu/glibc/glibc-ports-$(GLIBC_PORTS_VERSION).tar.bz2

$(WORK)/glibc-$(GLIBC_VERSION): $(WORK)/glibc-$(GLIBC_VERSION).tar.bz2 $(WORK)/glibc-ports-$(GLIBC_PORTS_VERSION).tar.bz2 $(WORK)/glibc-fix-versions-in-configure.patch
	tar -C $(WORK) -xvf $(WORK)/glibc-$(GLIBC_VERSION).tar.bz2
	cd $(WORK)/glibc-$(GLIBC_VERSION) && \
		tar xvjf $(WORK)/glibc-ports-$(GLIBC_PORTS_VERSION).tar.bz2 && \
		mv glibc-ports-$(GLIBC_PORTS_VERSION) ports && \
		patch -p1 -i $(WORK)/glibc-fix-versions-in-configure.patch && \
		sed -e 's/-lgcc_eh//g' -i Makeconfig
	touch $(WORK)/glibc-$(GLIBC_VERSION)

$(WORK)/build-glibc: $(WORK)/glibc-$(GLIBC_VERSION)
	mkdir -p $(WORK)/build-glibc
	touch $(WORK)/build-glibc
	
$(CLFS)/usr/lib/libc.so: $(WORK)/build-glibc $(WORK)/glibc-$(GLIBC_VERSION)
	@echo "[`date +'%F %T'`] Building glibc"
	cd $(WORK)/build-glibc && \
		export PATH=$(CROSSTOOLS)/bin:$$PATH && \
		echo "libc_cv_forced_unwind=yes" > config.cache && \
		echo "libc_cv_c_cleanup=yes" >> config.cache && \
		echo "libc_cv_gnu89_inline=yes" >> config.cache && \
		echo "install_root=$(CLFS)" > configparms && \
		unset CFLAGS && \
		unset CXXFLAGS && \
		BUILD_CC="gcc" \
		CC="$(TARGET)-gcc" \
		AR="$(TARGET)-ar" \
		RANLIB="$(TARGET)-ranlib" \
		$(WORK)/glibc-$(GLIBC_VERSION)/configure \
			--host=$(TARGET) \
			--build=$(HOST) \
			--prefix=/usr \
			--libexecdir=/usr/lib/glibc \
			--disable-profile \
			--enable-add-ons \
			--with-tls \
			--enable-kernel=2.6.0 \
			--with-__thread \
			--with-binutils=$(CROSSTOOLS)/bin \
			--with-headers=$(CLFS)/usr/include \
			--cache-file=config.cache && \
		make && \
		make install
	touch $(CLFS)/usr/lib/libc.so

.PHONY: glibc
glibc: linux-headers binutils gcc-static make $(CLFS)/usr/lib/libc.so

.PHONY: glibc-clean
glibc-clean:
	rm -vrf $(WORK)/build-glibc $(WORK)/glibc-$(GLIBC_VERSION)

.PHONY: glibc-distclean
glibc-distclean: glibc-clean
	rm -vf $(WORK)/glibc-$(GLIBC_VERSION).tar.bz2 $(WORK)/glibc-ports-$(GLIBC_VERSION).tar.bz2

# -----------------------------------------------------------------------
#
# gcc-final
#

$(WORK)/build-gcc-final: $(WORK)/gcc-$(GCC_VERSION)
	mkdir -p $(WORK)/build-gcc-final
	touch $(WORK)/build-gcc-final

$(CLFS)/lib/gcc: $(WORK)/build-gcc-final $(WORK)/gcc-$(GCC_VERSION)
	@echo "[`date +'%F %T'`] Building gcc-final"
	cd $(WORK)/build-gcc-final && \
		export PATH=$(CROSSTOOLS)/bin:$$PATH && \
		unset CC && \
		unset CXXFLAGS && \
		CFLAGS='-fgnu89-inline' \
		AR=ar \
		LDFLAGS="-Wl,-rpath,$(CROSSTOOLS)/lib" \
		$(WORK)/gcc-$(GCC_VERSION)/configure \
			--build=$(HOST) \
			--host=$(HOST) \
			--target=$(TARGET) \
			--prefix=$(CROSSTOOLS) \
			--libexecdir=$(CROSSTOOLS)/lib \
			--with-sysroot=$(CLFS) \
			--with-gmp=$(CROSSTOOLS) \
			--with-mpfr=$(CROSSTOOLS) \
			--with-mpc=$(CROSSTOOLS) \
			--without-headers \
			--disable-multilib \
			--disable-nls \
			--disable-decimal-float \
			--disable-libgomp \
			--disable-libmudflap \
			--disable-libssp \
			--disable-shared \
			--disable-thread \
			--enable-__cxa_atexit \
			--enable-c99 \
			--enable-long-long \
			--enable-languages=c,c++ \
			--enable-obsolete && \
		make && \
		make install
	touch $(CLFS)/lib/gcc

.PHONY: gcc-final
gcc-final: libgmp libmpfr glibc $(CLFS)/lib/gcc

.PHONY: gcc-final-clean
gcc-final-clean:
	rm -vrf $(WORK)/build-gcc-final $(WORK)/gcc-$(GCC_VERSION)

.PHONY: gcc-final-distclean
gcc-final-distclean: gcc-final-clean
	rm -vf $(WORK)/gcc-$(GCC_VERSION).tar.bz2

# -----------------------------------------------------------------------
#
# test
#

$(WORK)/test: $(WORK)/test.c
	@echo "[`date +'%F %T'`] Testing toolchain"
	export PATH=$(CROSSTOOLS)/bin:$$PATH && \
	unset CFLAGS && \
	unset CXXFLAGS && \
	unset CC && \
	AR=ar \
	LDFLAGS="-Wl,-rpath,$(CROSSTOOLS)/lib" \
	$(TARGET)-gcc -O2 -pipe -Wall -o $(WORK)/test $(WORK)/test.c
	[ "`file -b $(WORK)/test | cut -d',' -f2 | sed 's| ||g'`" = "ARM"  ] || exit 1
	touch $(WORK)/test

.PHONY: test
test: $(WORK)/test

.PHONY: test-clean
test-clean:
	rm -vrf $(WORK)/test

.PHONY: test-distclean
test-distclean: test-clean

# End of file
