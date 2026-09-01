# ppnet 架构

[English](ARCHITECTURE.md)

可移植核心持有协议编码、验证、有界 ARP 状态、请求关联、超时策略和统计。它不能
导入 oscore 或 osbare；每个 target 必须提供且只提供一个 packet-port 实现。

IPv4 address 使用 canonical `u32`，例如 `0x0A00020F`；MAC address 使用
`u64` 的低 48 位。frame byte 始终按 network byte order 显式读写，使 ABI 不依赖
宿主 endian 或 struct layout。

receive path fail closed：dispatch 前验证 Ethernet destination、IPv4 version、
header length、total length、checksum、destination、fragmentation flag 和
transport 边界。v0.1 只接受 20 字节 header 的未分片 IPv4。未知流量被忽略；
malformed 流量增加有界诊断计数。

TCP retransmission 和 TLS cryptography 明确不进入 pplang 核心。v0.2 将在类型化
ppnet 合同后适配 uIP 和 BearSSL。
