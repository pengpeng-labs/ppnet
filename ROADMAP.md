# ppnet roadmap

[Simplified Chinese](ROADMAP.zh-CN.md)

- [x] N0: define component, authority, packet port, and ownership boundaries.
- [x] N1: implement byte order, checksum, Ethernet, and bounded ARP.
- [x] N2: implement strict IPv4 and ICMP echo.
- [x] N3: implement UDP and bounded DNS A queries.
- [x] N4: verify deterministic host protocol and malformed-frame cases.
- [x] N5: verify QEMU e1000 ARP and ICMP over oscore 0.1.2.
- [x] N6: publish ppnet v0.1.0 with locked dependencies and CI.

Version 0.2 integrates uIP TCP and BearSSL TLS as external C components behind
pplang policy and typed glue. DHCP and HTTP may be added on that foundation.

## Version 0.2

- [x] N7: reproducibly build pinned uIP 1.0 and BearSSL 0.6 sources.
- [x] N8: publish one-session uIP TCP transport with bounded queues.
- [x] N9: verify adapter bounds and a QEMU HTTP connect/send/receive path.
- [x] N10: adapt BearSSL to oscore entropy and UTC wall-clock services.
- [x] N11: verify QEMU TLS/HTTPS and reject an invalid certificate hostname.
- [x] N12: publish ppnet v0.2.0 with locked dependencies and CI.

## Version 0.2.1

- [x] Isolate BearSSL host tools from freestanding build variables.
- [x] Disable Unix entropy and time autodetection in the bare-metal profile.
- [x] Reject both invalid hostnames and certificates from an untrusted CA.
- [x] Publish ppnet v0.2.1 after Linux CI passes.

## Later boundaries

HTTP semantics belong in a separate `pphttp` component over ppnet TCP/TLS;
they do not belong in the packet and transport component. A ppnet v0.3 should
be demand-driven by product use. Current candidates are DHCP, multiple bounded
sessions, and IPv6; none is committed until ppos or another host needs it.
