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

实现按使用需求分层链接：`datagram.pp` 不依赖 C；`tcp_stack.pp` 增加 uIP
adapter；`ppnet.pp` 再增加 BearSSL adapter。pplang 持有 authority check、上限、
timeout 和同步 API。C adapter 将窄类型调用翻译为上游 state machine。uIP 持有
TCP sequencing/retransmission；BearSSL 持有 TLS record、cryptography、X.509
path validation 和 hostname validation。

两个上游项目都不能直接调用 osbare。frame、monotonic time、entropy 和 UTC time
全部通过 ppnet 的 oscore port。上游源码复制到被忽略的 build storage，并使用
所选 compiler 重新构建；绝不原地 patch。
