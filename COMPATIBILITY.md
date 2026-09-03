# Compatibility

[Simplified Chinese](COMPATIBILITY.zh-CN.md)

ppnet 0.2.2 requires pplang, pplc, and pptc 0.4.0. Its production port uses
oscore 0.1.4, which pins osbare 0.1.3. QEMU acceptance covers an x86-64 PC, the
osbare e1000 device, and QEMU user networking at `10.0.2.0/24`.

The portable ABI does not depend on e1000 or QEMU. Other hosts may implement
the five-operation packet port while preserving complete Ethernet frames and a
monotonic millisecond clock. TLS hosts must additionally provide oscore entropy
and a valid UTC wall clock. The supported TLS profile is client-side TLS 1.2;
TLS 1.3 and a system CA store are outside version 0.2.
