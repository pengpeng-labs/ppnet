# ppnet

[Simplified Chinese](README.zh-CN.md)

`ppnet` is the bounded network-protocol component for the pp operating-system
stack. Version 0.2.0 combines an inspectable pplang datagram path with pinned,
upstream implementations of the standards-heavy layers: uIP 1.0 for TCP and
BearSSL 0.6 for TLS 1.2.

ppnet runs over a five-operation packet port: MAC address, send, receive,
monotonic milliseconds, and idle. TLS additionally consumes oscore entropy and
UTC wall-clock services. The production adapter uses oscore 0.1.4; host tests
use a deterministic in-memory link. NIC drivers remain in osbare.

```text
DNS / HTTP / HTTPS clients
          |
 pplang policy and bounds
     /             \
uIP TCP         BearSSL TLS
          |
 packet + clock + entropy ports
          |
        oscore
```

Version 0.2 provides one synchronous TCP/TLS session, bounded queues, hostname
and certificate validation, and QEMU e1000 HTTP/HTTPS acceptance. It is not a
POSIX socket layer and does not provide DHCP, IPv6, IP fragmentation, server
sockets, or concurrent connections.

See [Architecture](ARCHITECTURE.md), [ABI](ABI.md), and
[Roadmap](ROADMAP.md).

## Verification

With pptc 0.4.0 and an osbare 0.1.3 checkout available:

```sh
make verify PPTC=/path/to/pp OSBARE_DIR=/path/to/osbare HOST_CC=cc
```

This runs deterministic protocol tests and QEMU e1000 ARP/ICMP, HTTP, TLS,
HTTPS, and invalid-hostname acceptance. Upstream source identities and licenses
are recorded in [Third-party sources](THIRD_PARTY.md). ppnet source is licensed
under either Apache 2.0 or MIT, at your option.
