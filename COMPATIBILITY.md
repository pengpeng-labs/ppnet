# Compatibility

[Simplified Chinese](COMPATIBILITY.zh-CN.md)

ppnet 0.1.0 requires pplang, pplc, and pptc 0.4.0. Its production packet port
uses oscore 0.1.2, which pins osbare 0.1.1. QEMU acceptance covers an x86-64 PC,
the osbare e1000 device, and QEMU user networking at `10.0.2.0/24`.

The portable ABI does not depend on e1000 or QEMU. Other hosts may implement
the five-operation packet port while preserving complete Ethernet frames and a
monotonic millisecond clock.
