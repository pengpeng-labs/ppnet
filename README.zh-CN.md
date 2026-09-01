# ppnet

[English](README.md)

`ppnet` 是 pp 操作系统栈中有界的网络协议组件。v0.1.0 使用 pplang 实现可检查
的 datagram 路径：Ethernet II、ARP、IPv4、ICMP echo、UDP 和 DNS A-record
client。

ppnet 运行在包含五项操作的 packet port 上：MAC address、send、receive、
monotonic milliseconds 和 idle。生产 adapter 使用 oscore 0.1.2，宿主测试使用
确定性的内存链路；NIC driver 仍由 osbare 持有。

```text
DNS / future HTTP clients
          |
        ppnet
          |
 bounded packet + clock port
          |
        oscore
```

v0.1 明确不提供 socket、DHCP、IPv6、fragmentation、并发 flow、TCP 或 TLS。
v0.2 计划通过 uIP adapter 提供 TCP、通过 BearSSL adapter 提供 TLS；ppnet 不会
重新实现这些复杂标准。

详见[架构](ARCHITECTURE.zh-CN.md)、[ABI](ABI.zh-CN.md)和
[路线图](ROADMAP.zh-CN.md)。

## 验证

准备好 pptc 0.4.0 和 osbare 0.1.1 checkout 后运行：

```sh
make verify PPTC=/path/to/pp OSBARE_DIR=/path/to/osbare
```

该命令执行确定性协议套件和 QEMU e1000 ARP/ICMP 验收。源码可按 Apache 2.0
或 MIT 中任一许可证使用。
