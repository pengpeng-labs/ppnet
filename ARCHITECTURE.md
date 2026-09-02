# ppnet architecture

[Simplified Chinese](ARCHITECTURE.zh-CN.md)

The portable core owns protocol encoding, validation, bounded ARP state,
request correlation, timeout policy, and statistics. It cannot import oscore
or osbare. A target provides exactly one packet-port implementation.

IPv4 addresses are canonical `u32` values such as `0x0A00020F`; MAC addresses
are the low 48 bits of a `u64`. Frame bytes are read and written explicitly in
network byte order. This keeps the ABI independent of host endian and struct
layout.

The receive path fails closed: it validates Ethernet destination, IPv4 version,
header length, total length, checksum, destination, fragmentation flags, and
transport bounds before dispatch. Version 0.1 accepts only unfragmented IPv4
with a 20-byte header. Unknown traffic is ignored; malformed traffic increments
a bounded diagnostic counter.

The implementation is layered so consumers link only what they use:
`datagram.pp` is C-free; `tcp_stack.pp` adds the uIP adapter; `ppnet.pp` adds
the BearSSL adapter. pplang owns authority checks, limits, timeouts, and the
synchronous API. C adapters translate narrow typed calls into upstream state
machines. uIP owns TCP sequencing and retransmission; BearSSL owns TLS records,
cryptography, X.509 path validation, and hostname validation.

Neither upstream project may call osbare directly. All frames, monotonic time,
entropy, and UTC time cross ppnet's oscore port. Upstream trees are copied into
ignored build storage and rebuilt with the selected compiler; they are never
patched in place.
