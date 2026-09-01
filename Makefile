PPTC ?= pp
OSBARE_DIR ?= ../osbare
AS := x86_64-elf-as
CC := x86_64-elf-gcc
LD := x86_64-elf-ld
AR := x86_64-elf-ar
OBJCOPY := x86_64-elf-objcopy
QEMU := qemu-system-x86_64

.PHONY: check test test-protocol test-qemu verify clean

check:
	$(PPTC) check --name protocol-smoke --locked
	$(PPTC) check --name qemu-smoke --locked

test-protocol:
	$(PPTC) run --name protocol-smoke --locked

test-qemu:
	PPTC=$(PPTC) OSBARE_DIR=$(OSBARE_DIR) AS=$(AS) CC=$(CC) LD=$(LD) \
		AR=$(AR) OBJCOPY=$(OBJCOPY) sh tests/build-qemu.sh
	QEMU=$(QEMU) sh tests/run-qemu.sh

test: test-protocol test-qemu

verify: check test
	node tools/check-repository.mjs

clean:
	rm -rf build target
