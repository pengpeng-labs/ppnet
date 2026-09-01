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

authority 包含非零 owner，以及 send、receive 和 inspect capability。持有 address
或 transaction identifier 不代表获得权限。

packet port 返回本机 48-bit MAC，发送或接收一个完整 Ethernet frame，公开单调
毫秒时间，并等待下一个平台事件。receive 在没有 frame 时返回 0，port failure
返回负整数。

IPv4 option 和 fragment 会被拒绝。IPv4 UDP checksum 为 0 时允许省略，非零值
必须通过验证。DNS v1 发出一个 A/IN question，并返回该 transaction 扫描上限内
第一个匹配的 A/IN answer。
