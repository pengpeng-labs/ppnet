import "../src/tcp_stack.pp";
import "../src/oscore_port.pp";

static ppnet_http_response: [4096]u8;

fn ppnet_http_fail(message: str) {
    oscore_platform_write("PPNET HTTP FAIL ");
    oscore_platform_write(message);
    oscore_platform_write("\n");
    ppnet_tcp_abort();
    osbare_halt();
}

fn ppnet_http_contains(size: int, needle: str) -> bool {
    let source: *u8 = ptr_to_int(needle) as *u8;
    let length: int = len(needle) as int;
    let offset: int = 0;
    while (offset + length <= size) {
        let index: int = 0;
        while (index < length
            && ppnet_http_response[offset + index] == source[index]) {
            index = index + 1;
        }
        if (index == length) { return true; }
        offset = offset + 1;
    }
    return false;
}

fn osbare_main(boot_info: *OsBareBootInfo) {
    if (!oscore_init(boot_info)) { ppnet_http_fail("oscore-init"); }
    let principal: OsCorePrincipal = oscore_principal_root();
    if (!ppnet_oscore_port_init(principal)) { ppnet_http_fail("packet-port"); }
    let root: PpNetAuthority = ppnet_authority(1 as u64,
        ppnet_all_capabilities());
    let config: PpNetConfig;
    config.local_ipv4 = 0x0A00020F as u32;
    config.netmask = 0xFFFFFF00 as u32;
    config.gateway_ipv4 = 0x0A000202 as u32;
    config.dns_ipv4 = 0x0A000203 as u32;
    config.ttl = 64 as u64;
    if (ppnet_init(&root, &config) != 0 || ppnet_tcp_init(&root) != 0) {
        ppnet_http_fail("init");
    }
    if (ppnet_uip_contract_selftest() != 1) {
        ppnet_http_fail("contract");
    }
    if (ppnet_tcp_connect(&root, config.gateway_ipv4, 18080, 5000) != 0) {
        ppnet_http_fail("connect");
    }
    oscore_platform_write("PPNET TCP CONNECT PASS\n");
    let request: str = "GET /ppnet HTTP/1.1\r\nHost: 10.0.2.2\r\nConnection: close\r\n\r\n";
    if (ppnet_tcp_send(&root, ptr_to_int(request), len(request) as int, 5000)
        != len(request) as int) {
        ppnet_http_fail("send");
    }
    let total: int = 0;
    let receiving: bool = true;
    while (receiving && total < 4096) {
        let count: int = ppnet_tcp_receive(&root,
            ptr_to_int(&ppnet_http_response[total]), 4096 - total, 5000);
        if (count > 0) {
            total = total + count;
        } else if (count == 0) {
            receiving = false;
        } else {
            ppnet_http_fail("receive");
        }
    }
    if (!ppnet_http_contains(total, "PPNET_HTTP_OK")) {
        ppnet_http_fail("body");
    }
    ppnet_tcp_abort();
    oscore_platform_write("PPNET QEMU HTTP PASS\n");
    osbare_halt();
}
