#!/bin/sh
set -eu

QEMU=${QEMU:-qemu-system-x86_64}
log=build/ppnet-http-qemu.log
server_log=build/ppnet-http-server.log
: >"$log"
: >"$server_log"

node tests/http_server.mjs >"$server_log" 2>&1 &
server_pid=$!
qemu_pid=
trap 'test -z "$qemu_pid" || kill "$qemu_pid" 2>/dev/null || true; \
    kill "$server_pid" 2>/dev/null || true; \
    test -z "$qemu_pid" || wait "$qemu_pid" 2>/dev/null || true; \
    wait "$server_pid" 2>/dev/null || true' EXIT INT TERM

i=0
while [ "$i" -lt 100 ]; do
    if grep -q 'PPNET HTTP SERVER READY' "$server_log"; then break; fi
    if ! kill -0 "$server_pid" 2>/dev/null; then cat "$server_log"; exit 1; fi
    sleep 0.05
    i=$((i + 1))
done

"$QEMU" -machine pc -cpu max -m 128M -display none \
    -serial file:"$log" -monitor none -kernel build/ppnet-http.elf \
    -device e1000,netdev=net0 -netdev user,id=net0 \
    -no-reboot -no-shutdown &
qemu_pid=$!

i=0
while [ "$i" -lt 400 ]; do
    if grep -q 'PPNET QEMU HTTP PASS' "$log"; then
        cat "$log"
        exit 0
    fi
    if grep -q 'PPNET HTTP FAIL' "$log" || ! kill -0 "$qemu_pid" 2>/dev/null; then
        cat "$log"
        exit 1
    fi
    sleep 0.05
    i=$((i + 1))
done

cat "$log"
exit 1
