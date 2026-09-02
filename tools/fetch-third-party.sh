#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
destination=${THIRD_PARTY_BUILD:-"$root/build/third_party"}
uip_commit=a49def743f6e5c7d0c0f2d724f0b8e0c563a4a37
bearssl_hash=6705bba1714961b41a728dfc5debbe348d2966c117649392f8c8139efc83ff14

hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

mkdir -p "$destination"

if [ -n "${UIP_SOURCE:-}" ]; then
    test -f "$UIP_SOURCE/uip/uip.c"
    printf '%s\n' "$UIP_SOURCE" >"$destination/uip.path"
else
    if [ ! -d "$destination/uip/.git" ]; then
        rm -rf "$destination/uip"
        git clone --branch uip-1-0 --depth 1 \
            https://github.com/adamdunkels/uip.git "$destination/uip"
    fi
    test "$(git -C "$destination/uip" rev-parse HEAD)" = "$uip_commit"
    printf '%s\n' "$destination/uip" >"$destination/uip.path"
fi

if [ -n "${BEARSSL_SOURCE:-}" ]; then
    test -f "$BEARSSL_SOURCE/LICENSE.txt"
    test -f "$BEARSSL_SOURCE/src/ssl/ssl_client.c"
    printf '%s\n' "$BEARSSL_SOURCE" >"$destination/bearssl.path"
else
    archive="$destination/bearssl-0.6.tar.gz"
    if [ ! -f "$archive" ]; then
        curl -L https://bearssl.org/bearssl-0.6.tar.gz -o "$archive"
    fi
    test "$(hash_file "$archive")" = "$bearssl_hash"
    if [ ! -d "$destination/bearssl-0.6" ]; then
        tar -xzf "$archive" -C "$destination"
    fi
    printf '%s\n' "$destination/bearssl-0.6" >"$destination/bearssl.path"
fi

printf 'PPNET THIRD PARTY PASS\n'
