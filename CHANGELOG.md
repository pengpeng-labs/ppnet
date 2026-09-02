# Changelog

## 0.2.0

- Add a bounded, one-session TCP client using pinned uIP 1.0.
- Add a TLS 1.2 client using pinned BearSSL 0.6, oscore entropy and UTC time,
  caller-provided trust anchors, and mandatory hostname validation.
- Add reproducible upstream fetch/build scripts and explicit license records.
- Verify bare-metal HTTP and HTTPS over QEMU e1000, including invalid-hostname
  rejection.
- Update the production adapter to oscore 0.1.3.

## 0.1.0

- Establish the bounded ppnet v1 authority and packet-port contracts.
- Implement Ethernet II, bounded ARP, strict unfragmented IPv4, ICMP echo,
  UDP checksums, and bounded DNS A queries in pplang.
- Add deterministic malformed-frame tests and QEMU e1000 ARP/ICMP acceptance.
- Pin the production adapter to oscore 0.1.2 and osbare 0.1.1.
