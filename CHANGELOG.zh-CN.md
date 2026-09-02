# 变更记录

## 0.2.1

- 将 BearSSL host tool 与 freestanding compiler/linker 隔离。
- 在裸机 profile 中关闭 BearSSL Unix entropy/clock 自动探测；这些 service
  仍只由 oscore 提供。
- 验证拒绝 hostname 正确但由未受信 CA 签发的证书。

## 0.2.0

- 使用锁定的 uIP 1.0 增加有界的单 session TCP client。
- 使用锁定的 BearSSL 0.6 增加 TLS 1.2 client，接入 oscore entropy/UTC time、
  caller 提供的 trust anchor，并强制 hostname validation。
- 增加可复现的上游 fetch/build script 和明确的许可证记录。
- 在 QEMU e1000 上验证裸机 HTTP/HTTPS，包括错误 hostname 拒绝。
- 将生产 adapter 更新至 oscore 0.1.3。

## 0.1.0

- 建立有界的 ppnet v1 authority 和 packet-port 合同。
- 使用 pplang 实现 Ethernet II、有界 ARP、严格未分片 IPv4、ICMP echo、UDP
  checksum 和有界 DNS A query。
- 增加确定性的 malformed-frame 测试和 QEMU e1000 ARP/ICMP 验收。
- 将生产 adapter 锁定到 oscore 0.1.2 和 osbare 0.1.1。
