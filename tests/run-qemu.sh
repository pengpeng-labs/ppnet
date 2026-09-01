#!/bin/sh
set -eu

QEMU=${QEMU:-qemu-system-x86_64}
log=build/ppnet-qemu.log
: >"$log"

"$QEMU" -machine pc -cpu max -m 128M -display none \
    -serial file:"$log" -monitor none -kernel build/ppnet-smoke.elf \
    -device e1000,netdev=net0 -netdev user,id=net0 \
    -no-reboot -no-shutdown &
pid=$!
trap 'kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true' \
    EXIT INT TERM

i=0
while [ "$i" -lt 300 ]; do
    if grep -q 'PPNET READY' "$log"; then
        cat "$log"
        exit 0
    fi
    if grep -q 'PPNET FAIL' "$log" || ! kill -0 "$pid" 2>/dev/null; then
        cat "$log"
        exit 1
    fi
    sleep 0.05
    i=$((i + 1))
done

cat "$log"
exit 1
