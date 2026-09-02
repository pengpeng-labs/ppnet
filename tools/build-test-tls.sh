#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
third_party=${THIRD_PARTY_BUILD:-"$root/build/third_party"}
CC=${CC:-cc}
AR=${AR:-ar}

sh "$root/tools/generate-test-pki.sh"
bearssl=$(cat "$third_party/bearssl.path")
flags="-std=c11 -ffreestanding -fno-stack-protector -fno-pic -Os -m64 -mno-red-zone -mcmodel=kernel -mno-mmx -mno-sse -mno-sse2 -Wall -Wextra -Werror -I$root/c/include"
"$CC" $flags -I"$bearssl/inc" -I"$root/build/test-pki" \
    -c "$root/c/test_trust.c" -o "$third_party/test_trust.o"
"$AR" rcs "$third_party/libppnet-test-trust.a" "$third_party/test_trust.o"
printf 'PPNET TEST TLS BUILD PASS\n'
