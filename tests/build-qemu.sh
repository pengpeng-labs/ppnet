#!/bin/sh
set -eu

PPTC=${PPTC:-pp}
OSBARE_DIR=${OSBARE_DIR:-../osbare}
AS=${AS:-x86_64-elf-as}
CC=${CC:-x86_64-elf-gcc}
AR=${AR:-x86_64-elf-ar}
LD=${LD:-x86_64-elf-ld}
OBJCOPY=${OBJCOPY:-x86_64-elf-objcopy}

mkdir -p build
make -C "$OSBARE_DIR" component AS="$AS" CC="$CC" AR="$AR"
"$PPTC" build --name qemu-smoke
object=target/x86_64-unknown-none/debug/ppnet/qemu-smoke.o
"$LD" -z noexecstack -T "$OSBARE_DIR/arch/x86_64/kernel64.ld" \
    "$OSBARE_DIR/build/entry64.o" "$object" \
    "$OSBARE_DIR/build/libosbare.a" -o build/ppnet-kernel.elf64
"$OBJCOPY" -O binary build/ppnet-kernel.elf64 build/ppnet-kernel.bin
"$OBJCOPY" -I binary -O elf32-i386 -B i386 \
    --rename-section .data=.kernel,alloc,load,code,contents \
    build/ppnet-kernel.bin build/ppnet-kernel.bin.o
"$LD" -z noexecstack -m elf_i386 \
    -T "$OSBARE_DIR/arch/x86_64/boot32.ld" \
    "$OSBARE_DIR/build/boot32.o" build/ppnet-kernel.bin.o \
    -o build/ppnet-smoke.elf
