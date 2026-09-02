# ppnet ABI v1

[English](ABI.md)

## 上限

| 资源 | v1 上限 |
|---|---:|
| Ethernet frame | 1526 bytes |
| ARP entry | 8 |
| ARP lifetime | 60 秒 |
| DNS name | 253 bytes |
| DNS answer scan | 16 records |
| 并发同步 request | 1 |
| TCP session | 1 |
| TCP transmit queue | 32768 bytes |
| TCP receive queue | 32768 bytes |
| TLS hostname | 253 bytes |
| TLS trust anchor | 32 |
| operation timeout | 1 至 30000 毫秒 |

authority 包含非零 owner，以及 send、receive 和 inspect capability。持有 address
或 transaction identifier 不代表获得权限。

packet port 返回本机 48-bit MAC，发送或接收一个完整 Ethernet frame，公开单调
毫秒时间，并等待下一个平台事件。receive 在没有 frame 时返回 0，port failure
返回负整数。

IPv4 option 和 fragment 会被拒绝。IPv4 UDP checksum 为 0 时允许省略，非零值
必须通过验证。DNS v1 发出一个 A/IN question，并返回该 transaction 扫描上限内
第一个匹配的 A/IN answer。

TCP 是同步 client transport。send 只在 queue 中的 byte 被确认，或发生 error/
timeout 后返回；receive 返回 buffered byte，正常关闭返回 0，ppnet error 返回负数。
TLS 仅提供 client TLS 1.2。caller 必须在 connect 前配置非空 trust anchor。
adapter 要求 entropy 和 UTC wall time，并始终把请求 hostname 交给 BearSSL 执行
X.509 与 hostname validation。
