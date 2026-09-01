# 变更记录

## 0.1.0

- 建立有界的 ppnet v1 authority 和 packet-port 合同。
- 使用 pplang 实现 Ethernet II、有界 ARP、严格未分片 IPv4、ICMP echo、UDP
  checksum 和有界 DNS A query。
- 增加确定性的 malformed-frame 测试和 QEMU e1000 ARP/ICMP 验收。
- 将生产 adapter 锁定到 oscore 0.1.2 和 osbare 0.1.1。
