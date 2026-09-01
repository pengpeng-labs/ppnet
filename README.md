# ppnet

[Simplified Chinese](README.zh-CN.md)

`ppnet` is the bounded network-protocol component for the pp operating-system
stack. Version 0.1.0 implements the inspectable datagram path in pplang:
Ethernet II, ARP, IPv4, ICMP echo, UDP, and a DNS A-record client.

ppnet runs over a five-operation packet port: MAC address, send, receive,
monotonic milliseconds, and idle. The production adapter uses oscore 0.1.2;
host tests use a deterministic in-memory link. NIC drivers remain in osbare.

```text
DNS / future HTTP clients
          |
        ppnet
          |
 bounded packet + clock port
          |
        oscore
```

Version 0.1 deliberately has no sockets, DHCP, IPv6, fragmentation,
concurrent flows, TCP, or TLS. TCP is planned as a uIP adapter and TLS as a
BearSSL adapter in version 0.2; ppnet will not reimplement those standards.

See [Architecture](ARCHITECTURE.md), [ABI](ABI.md), and
[Roadmap](ROADMAP.md).

## Verification

With pptc 0.4.0 and an osbare 0.1.1 checkout available:

```sh
make verify PPTC=/path/to/pp OSBARE_DIR=/path/to/osbare
```

This runs the deterministic protocol suite and the QEMU e1000 ARP/ICMP
acceptance. The source is licensed under either Apache 2.0 or MIT, at your
option.
