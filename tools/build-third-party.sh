#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
destination=${THIRD_PARTY_BUILD:-"$root/build/third_party"}
CC=${CC:-cc}
AR=${AR:-ar}

sh "$root/tools/fetch-third-party.sh"
uip=$(cat "$destination/uip.path")
bearssl_source=$(cat "$destination/bearssl.path")
objects="$destination/objects"
mkdir -p "$objects/uip" "$objects/bearssl"

flags="-std=c11 -ffreestanding -fno-stack-protector -fno-pic -Os -m64 -mno-red-zone -mcmodel=kernel -mno-mmx -mno-sse -mno-sse2 -Wall -Wextra -Werror -I$root/c/include"
uip_flags="$flags -Wno-error=type-limits -Wno-error=unused-label -Wno-error=unused-const-variable"

"$CC" $uip_flags -I"$root/c/uip" -I"$uip/uip" \
    -c "$uip/uip/uip.c" -o "$objects/uip/uip.o"
"$CC" $uip_flags -I"$root/c/uip" -I"$uip/uip" \
    -c "$uip/uip/uip_arp.c" -o "$objects/uip/uip_arp.o"
"$CC" $flags -I"$root/c/uip" -I"$uip/uip" \
    -c "$root/c/uip_adapter.c" -o "$objects/uip/uip_adapter.o"
"$AR" rcs "$destination/libuip-core.a" \
    "$objects/uip/uip.o" "$objects/uip/uip_arp.o" \
    "$objects/uip/uip_adapter.o"

"$CC" $flags -c "$root/c/freestanding_libc.c" \
    -o "$objects/freestanding_libc.o"
"$AR" rcs "$destination/libppnet-c.a" "$objects/freestanding_libc.o"

"$CC" $flags -I"$bearssl_source/inc" -c "$root/c/tls_adapter.c" \
    -o "$objects/tls_adapter.o"
"$AR" rcs "$destination/libppnet-tls.a" "$objects/tls_adapter.o"

bearssl="$destination/bearssl-work"
rm -rf "$bearssl"
cp -R "$bearssl_source" "$bearssl"
rm -rf "$bearssl/build"
bearssl_flags="$flags -DBR_AES_X86NI=0 -DBR_SSE2=0 -DBR_RDRAND=0 \
    -DBR_USE_URANDOM=0 -DBR_USE_WIN32_RAND=0 \
    -DBR_USE_UNIX_TIME=0 -DBR_USE_WIN32_TIME=0"
make -C "$bearssl" lib \
    CC="$CC" AR="$AR" \
    CFLAGS="$bearssl_flags -I$bearssl/inc" >/dev/null
cp "$bearssl/build/libbearssl.a" "$destination/libbearssl.a"

printf 'PPNET THIRD PARTY BUILD PASS\n'
