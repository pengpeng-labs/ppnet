import "../src/ppnet.pp";
import "../src/oscore_port.pp";

extern fn ppnet_test_trust_anchors() -> u64;
extern fn ppnet_test_trust_anchor_count() -> int;

static ppnet_https_response: [4096]u8;

fn ppnet_https_fail(message: str) {
    oscore_platform_write("PPNET HTTPS FAIL ");
    oscore_platform_write(message);
    oscore_platform_write(" error=");
    oscore_platform_hex(ppnet_tls_error() as u64);
    oscore_platform_write("\n");
    ppnet_tls_close();
    osbare_halt();
}

fn ppnet_https_contains(size: int, needle: str) -> bool {
    let source: *u8 = ptr_to_int(needle) as *u8;
    let length: int = len(needle) as int;
    let offset: int = 0;
    while (offset + length <= size) {
        let index: int = 0;
        while (index < length
            && ppnet_https_response[offset + index] == source[index]) {
            index = index + 1;
        }
        if (index == length) { return true; }
        offset = offset + 1;
    }
    return false;
}

fn osbare_main(boot_info: *OsBareBootInfo) {
    if (!oscore_init(boot_info)) { ppnet_https_fail("oscore-init"); }
    let principal: OsCorePrincipal = oscore_principal_root();
    if (!ppnet_oscore_port_init(principal)) { ppnet_https_fail("packet-port"); }
    let root: PpNetAuthority = ppnet_authority(1 as u64,
        ppnet_all_capabilities());
    let config: PpNetConfig;
    config.local_ipv4 = 0x0A00020F as u32;
    config.netmask = 0xFFFFFF00 as u32;
    config.gateway_ipv4 = 0x0A000202 as u32;
    config.dns_ipv4 = 0x0A000203 as u32;
    config.ttl = 64 as u64;
    if (ppnet_init(&root, &config) != 0 || ppnet_tcp_init(&root) != 0
        || ppnet_tls_configure(&root, ppnet_test_trust_anchors(),
            ppnet_test_trust_anchor_count()) != 0) {
        ppnet_https_fail("init");
    }
    if (ppnet_tls_connect(&root, config.gateway_ipv4, 18443,
            "ppnet.test", 10000) != 0) {
        ppnet_https_fail("handshake");
    }
    oscore_platform_write("PPNET TLS HANDSHAKE PASS\n");
    let request: str = "GET /secure HTTP/1.1\r\nHost: ppnet.test\r\nConnection: close\r\n\r\n";
    if (ppnet_tls_send(&root, ptr_to_int(request), len(request) as int, 5000)
        != len(request) as int) {
        ppnet_https_fail("send");
    }
    let total: int = 0;
    while (total < 4096 && !ppnet_https_contains(total, "PPNET_HTTPS_OK")) {
        let count: int = ppnet_tls_receive(&root,
            ptr_to_int(&ppnet_https_response[total]), 4096 - total, 5000);
        if (count <= 0) { ppnet_https_fail("receive"); }
        total = total + count;
    }
    if (!ppnet_https_contains(total, "PPNET_HTTPS_OK")) {
        ppnet_https_fail("body");
    }
    ppnet_tls_close();
    if (ppnet_tls_connect(&root, config.gateway_ipv4, 18443,
            "wrong.ppnet.test", 5000) == 0) {
        ppnet_https_fail("hostname-validation");
    }
    oscore_platform_write("PPNET TLS HOSTNAME REJECT PASS\n");
    if (ppnet_tls_connect(&root, config.gateway_ipv4, 18444,
            "ppnet.test", 5000) == 0) {
        ppnet_https_fail("trust-validation");
    }
    oscore_platform_write("PPNET TLS UNTRUSTED REJECT PASS\n");
    oscore_platform_write("PPNET QEMU HTTPS PASS\n");
    osbare_halt();
}
