# ppnet

[English](README.md)

`ppnet` 是 pp 操作系统栈中有界的网络协议组件。v0.2.0 将 pplang 编写的可检查
datagram 路径，与锁定的复杂标准上游实现结合：uIP 1.0 负责 TCP，BearSSL 0.6
负责 TLS 1.2。

ppnet 运行在包含五项操作的 packet port 上：MAC address、send、receive、
monotonic milliseconds 和 idle。TLS 还使用 oscore 的 entropy 与 UTC wall-clock
service。生产 adapter 使用 oscore 0.1.3，宿主测试使用确定性的内存链路；NIC
driver 仍由 osbare 持有。

```text
DNS / HTTP / HTTPS clients
          |
 pplang policy and bounds
     /             \
uIP TCP         BearSSL TLS
          |
 packet + clock + entropy ports
          |
        oscore
```

v0.2 提供一个同步 TCP/TLS session、有界 queue、hostname/certificate validation，
以及 QEMU e1000 HTTP/HTTPS 验收。它不是 POSIX socket layer，不提供 DHCP、
IPv6、IP fragmentation、server socket 或并发 connection。

详见[架构](ARCHITECTURE.zh-CN.md)、[ABI](ABI.zh-CN.md)和
[路线图](ROADMAP.zh-CN.md)。

## 验证

准备好 pptc 0.4.0 和 osbare 0.1.1 checkout 后运行：

```sh
make verify PPTC=/path/to/pp OSBARE_DIR=/path/to/osbare HOST_CC=cc
```

该命令执行确定性协议测试，以及 QEMU e1000 ARP/ICMP、HTTP、TLS、HTTPS 和错误
hostname 验收。上游源码身份和许可证记录在[第三方源码](THIRD_PARTY.zh-CN.md)。
ppnet 源码可按 Apache 2.0 或 MIT 中任一许可证使用。
