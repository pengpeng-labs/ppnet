# ppnet ABI v1

[Simplified Chinese](ABI.zh-CN.md)

## Bounds

| Resource | v1 bound |
|---|---:|
| Ethernet frame | 1526 bytes |
| ARP entries | 8 |
| ARP lifetime | 60 seconds |
| DNS name | 253 bytes |
| DNS answer scan | 16 records |
| Concurrent synchronous request | 1 |

Authorities contain a nonzero owner plus send, receive, and inspect
capabilities. Possessing an address or transaction identifier grants no
authority.

The packet port returns the local 48-bit MAC, sends or receives one complete
Ethernet frame, publishes monotonic milliseconds, and idles until the next
platform event. Receive returns zero when no frame is available and a negative
integer on a port failure.

IPv4 options and fragments are rejected. UDP checksum zero is accepted for
IPv4; nonzero checksums are validated. DNS v1 issues one A/IN question and
returns the first bounded A/IN answer matching its transaction.
