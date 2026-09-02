# ppnet 路线图

[English](ROADMAP.md)

- [x] N0：定义组件、authority、packet port 和所有权边界。
- [x] N1：实现 byte order、checksum、Ethernet 和有界 ARP。
- [x] N2：实现严格 IPv4 和 ICMP echo。
- [x] N3：实现 UDP 和有界 DNS A query。
- [x] N4：验证确定性宿主协议和 malformed-frame case。
- [x] N5：通过 oscore 0.1.2 验证 QEMU e1000 ARP 和 ICMP。
- [x] N6：以锁定依赖和 CI 发布 ppnet v0.1.0。

v0.2 在 pplang policy 和类型化 glue 后接入外部 C 组件 uIP TCP 和 BearSSL TLS，
并可在该地基上增加 DHCP 与 HTTP。

## v0.2

- [x] N7：从锁定的 uIP 1.0 和 BearSSL 0.6 源码可复现构建。
- [x] N8：发布带有界 queue 的单 session uIP TCP transport。
- [x] N9：验证 adapter 上限与 QEMU HTTP connect/send/receive path。
- [x] N10：将 BearSSL 适配到 oscore entropy 和 UTC wall-clock service。
- [x] N11：验证 QEMU TLS/HTTPS，并拒绝错误的 certificate hostname。
- [x] N12：以锁定依赖和 CI 发布 ppnet v0.2.0。
