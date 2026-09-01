import "memory_port.pp";
import "../src/ppnet.pp";

fn ppnet_test_fail(code: int) -> int {
    println(code);
    return code;
}

fn main() -> int {
    ppnet_test_reset();
    let root: PpNetAuthority = ppnet_authority(1 as u64,
        ppnet_all_capabilities());
    let inspect: PpNetAuthority = ppnet_authority(2 as u64,
        ppnet_cap_inspect());
    let config: PpNetConfig;
    config.local_ipv4 = 0x0A00020F as u32;
    config.netmask = 0xFFFFFF00 as u32;
    config.gateway_ipv4 = 0x0A000202 as u32;
    config.dns_ipv4 = 0x0A000203 as u32;
    config.ttl = 64 as u64;
    if (ppnet_init(&inspect, &config) != 0) { return ppnet_test_fail(1); }
    if (ppnet_arp_resolve(&inspect, config.gateway_ipv4, 100) != (0 as u64)) {
        return ppnet_test_fail(2);
    }
    let resolved: u64 = ppnet_arp_resolve(&root, 0x08080808 as u32, 100);
    if (resolved != ppnet_test_peer_mac() || ppnet_test_sent_size != 42) {
        return ppnet_test_fail(3);
    }
    let sent: u64 = ptr_to_int(&ppnet_test_sent_frame[0]);
    if (ppnet_load_mac(sent) != ppnet_mac_broadcast()
        || ppnet_load_mac(sent + (6 as u64)) != ppnet_port_mac()
        || ppnet_load_be16(sent + (12 as u64)) != 0x0806
        || ppnet_load_be32(sent + (38 as u64)) != config.gateway_ipv4) {
        return ppnet_test_fail(4);
    }
    if (ppnet_ping(&root, 0x08080808 as u32, 100) != 0) {
        return ppnet_test_fail(5);
    }
    if (ppnet_dns_resolve(&root, "example.com", 100) != (0x01020304 as u32)
        || ppnet_dns_resolve(&root, "bad..name", 100) != (0 as u32)
        || ppnet_test_bad_dns() != ppnet_error_protocol()) {
        return ppnet_test_fail(6);
    }
    sent = ptr_to_int(&ppnet_test_sent_frame[0]);
    let udp_size: int = ppnet_load_be16(sent + (38 as u64));
    if (ppnet_load_be16(sent + (34 as u64)) != 49152
        || ppnet_load_be16(sent + (36 as u64)) != 53
        || ppnet_udp_checksum(config.local_ipv4, config.dns_ipv4,
            sent + (34 as u64), udp_size) != 0) {
        return ppnet_test_fail(7);
    }
    ppnet_test_queue_bad_ipv4();
    if (ppnet_poll(&root) != ppnet_error_protocol()) { return ppnet_test_fail(8); }
    ppnet_test_queue_short();
    if (ppnet_poll(&root) != ppnet_error_protocol()) { return ppnet_test_fail(9); }
    let status: PpNetStatus;
    if (!ppnet_status(&inspect, &status) || !status.initialized
        || status.mac != ppnet_port_mac() || status.transmitted != (4 as u64)
        || status.received != (6 as u64) || status.dropped != (2 as u64)
        || status.arp_entries != (2 as u64)) {
        return ppnet_test_fail(10);
    }
    return 0;
}
