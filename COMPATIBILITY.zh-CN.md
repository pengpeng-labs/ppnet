# 兼容性

[English](COMPATIBILITY.md)

ppnet 0.1.0 依赖 pplang、pplc 和 pptc 0.4.0。生产 packet port 使用 oscore
0.1.2，后者锁定 osbare 0.1.1。QEMU 验收覆盖 x86-64 PC、osbare e1000 device
和位于 `10.0.2.0/24` 的 QEMU user networking。

可移植 ABI 不依赖 e1000 或 QEMU。其他宿主可以实现五项 packet port，同时保持
完整 Ethernet frame 和单调毫秒时钟语义。
