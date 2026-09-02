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

## v0.2.1

- [x] 将 BearSSL host tool 与 freestanding build variable 隔离。
- [x] 在裸机 profile 中关闭 Unix entropy/time 自动探测。
- [x] 同时拒绝错误 hostname 和来自未受信 CA 的证书。
- [x] Linux CI 通过后发布 ppnet v0.2.1。

## 后续边界

HTTP 语义属于构建在 ppnet TCP/TLS 之上的独立 `pphttp` 组件，不进入 packet 与
transport 组件。ppnet v0.3 应由产品需求驱动；当前候选为 DHCP、多个有界 session
和 IPv6，在 ppos 或其他 host 实际需要前都不承诺实现。
