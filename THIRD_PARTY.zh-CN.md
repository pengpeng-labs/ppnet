# 第三方源码

[English](THIRD_PARTY.md)

ppnet 通过窄 C adapter 使用上游协议和密码学实现。上游源码进入被忽略的 build
storage，绝不原地修改。

| 组件 | 版本 | 不可变身份 | 许可证 |
|---|---|---|---|
| uIP | 1.0 | tag `uip-1-0`，commit `a49def743f6e5c7d0c0f2d724f0b8e0c563a4a37` | 3-clause BSD |
| BearSSL | 0.6 | `bearssl-0.6.tar.gz`，SHA-256 `6705bba1714961b41a728dfc5debbe348d2966c117649392f8c8139efc83ff14` | MIT |

uIP 官方仓库为 `https://github.com/adamdunkels/uip`；BearSSL 官方 archive 为
`https://bearssl.org/bearssl-0.6.tar.gz`。

`tools/fetch-third-party.sh` 验证这些身份。开发者可以通过 `UIP_SOURCE` 和
`BEARSSL_SOURCE` 指向已解压的只读源码树；构建仍验证预期文件，且不会写入源码树。
