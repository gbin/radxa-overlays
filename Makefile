KERNELRELEASE ?= $(shell uname -r)
KSRC ?= /lib/modules/$(KERNELRELEASE)/build

CONFIG_CLK_RK3308 ?= rockchip
CONFIG_CLK_RK3328 ?= rockchip
CONFIG_CLK_RK3399 ?= rockchip
CONFIG_CLK_RK3568 ?= rockchip
CONFIG_CLK_RK3588 ?= rockchip
CONFIG_ARCH_MESON ?= amlogic
include $(wildcard arch/arm64/boot/dts/*/overlays/Makefile)

DTBO-AMLOGIC	:=	$(addprefix arch/arm64/boot/dts/amlogic/overlays/,$(dtb-amlogic))
DTBO-ROCKCHIP	:=	$(addprefix arch/arm64/boot/dts/rockchip/overlays/,$(dtb-rockchip))
DTBO		:=	$(DTBO-AMLOGIC) $(DTBO-ROCKCHIP)
TMP		:=	$(addsuffix .tmp,$(DTBO))

#
# Build
#
.PHONY: build
build: build-doc

.PHONY: build-dtbo
build-dtbo: $(DTBO)

%.dtbo: %.dts
	cpp -nostdinc -undef -x assembler-with-cpp -E -I "$(KSRC)/include" "$<" "$@.tmp"
	dtc -q -@ -I dts -O dtb -o "$@" "$@.tmp"

DOCS		:=	SOURCE
.PHONY: build-doc
build-doc: $(DOCS)

.PHONY: SOURCE
SOURCE: 
	echo -e "git clone $(shell git remote get-url origin)\ngit checkout $(shell git rev-parse HEAD)" > "$@"

#
# Clean
#
.PHONY: distclean
distclean: clean


.PHONY: clean-dtbo
clean-dtbo:
	rm -rf $(DTBO) $(TMP)

.PHONY: clean
clean: clean-dtbo
	rm -rf debian/.debhelper debian/radxa-overlays-dkms debian/debhelper-build-stamp debian/files debian/*.debhelper.log debian/*.*.debhelper debian/*.substvars debian/tmp

#
# Release
#
.PHONY: dch
dch: debian/changelog build-doc
	EDITOR=true gbp dch --commit --debian-branch=main --release --dch-opt=--upstream

.PHONY: deb
deb: debian build-doc
	debuild --no-lintian --lintian-hook "lintian --fail-on error,warning --suppress-tags bad-distribution-in-changes-file -- %p_%v_*.changes" --no-sign -b
