# Third-party sources

[Simplified Chinese](THIRD_PARTY.zh-CN.md)

ppnet uses upstream protocol and cryptographic implementations through narrow
C adapters. Upstream source is fetched into ignored build storage and is never
modified in place.

| Component | Version | Immutable identity | License |
|---|---|---|---|
| uIP | 1.0 | tag `uip-1-0`, commit `a49def743f6e5c7d0c0f2d724f0b8e0c563a4a37` | 3-clause BSD |
| BearSSL | 0.6 | `bearssl-0.6.tar.gz`, SHA-256 `6705bba1714961b41a728dfc5debbe348d2966c117649392f8c8139efc83ff14` | MIT |

The official uIP repository is `https://github.com/adamdunkels/uip`. The
official BearSSL archive is `https://bearssl.org/bearssl-0.6.tar.gz`.

`tools/fetch-third-party.sh` verifies these identities. Developers may set
`UIP_SOURCE` and `BEARSSL_SOURCE` to already extracted, read-only source trees;
the build still verifies the expected files and never writes into those trees.
The freestanding BearSSL profile disables OS entropy and clock autodetection;
ppnet injects both services through oscore instead.
