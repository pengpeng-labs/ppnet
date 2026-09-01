import "types.pp";
import "bytes.pp";

static ppnet_config_value: PpNetConfig;
static ppnet_mac_value: u64;
static ppnet_initialized_value: bool;
static ppnet_transmitted_value: u64;
static ppnet_received_value: u64;
static ppnet_dropped_value: u64;
static ppnet_ipv4_identifier: int;
static ppnet_frame: [1526]u8;
static ppnet_payload: [1480]u8;
static ppnet_arp_ip: [8]u32;
static ppnet_arp_mac: [8]u64;
static ppnet_arp_expires: [8]u64;
static ppnet_arp_active: [8]bool;
static ppnet_arp_next: int;
static ppnet_ping_identifier: int;
static ppnet_ping_sequence: int;
static ppnet_ping_target: u32;
static ppnet_ping_ready: bool;
static ppnet_dns_transaction: int;
static ppnet_dns_port: int;
static ppnet_dns_ready: bool;
static ppnet_dns_result: u32;

fn ppnet_reset_state() {
    ppnet_initialized_value = false;
    ppnet_transmitted_value = 0 as u64;
    ppnet_received_value = 0 as u64;
    ppnet_dropped_value = 0 as u64;
    ppnet_ipv4_identifier = 1;
    ppnet_arp_next = 0;
    ppnet_ping_identifier = 0x5050;
    ppnet_ping_sequence = 0;
    ppnet_ping_target = 0 as u32;
    ppnet_ping_ready = false;
    ppnet_dns_transaction = 0x5000;
    ppnet_dns_port = 49152;
    ppnet_dns_ready = false;
    ppnet_dns_result = 0 as u32;
    let index: int = 0;
    while (index < 8) {
        ppnet_arp_active[index] = false;
        ppnet_arp_ip[index] = 0 as u32;
        ppnet_arp_mac[index] = 0 as u64;
        ppnet_arp_expires[index] = 0 as u64;
        index = index + 1;
    }
    ppnet_zero(ptr_to_int(&ppnet_frame[0]), 1526);
    ppnet_zero(ptr_to_int(&ppnet_payload[0]), 1480);
}

fn ppnet_init(authority: *PpNetAuthority, config: *PpNetConfig) -> int {
    if (!ppnet_authority_allows(authority, ppnet_cap_inspect())) {
        return ppnet_error_denied();
    }
    if (config == (0 as *PpNetConfig) || config.local_ipv4 == (0 as u32)
        || config.netmask == (0 as u32) || config.gateway_ipv4 == (0 as u32)
        || config.dns_ipv4 == (0 as u32) || config.ttl < (1 as u64)
        || config.ttl > (255 as u64)) {
        return ppnet_error_invalid();
    }
    ppnet_reset_state();
    ppnet_mac_value = ppnet_port_mac();
    if (ppnet_mac_value == (0 as u64)
        || ppnet_mac_value > ppnet_mac_mask()) {
        return ppnet_error_port();
    }
    ppnet_config_value = *config;
    ppnet_initialized_value = true;
    return 0;
}

fn ppnet_status(authority: *PpNetAuthority, output: *PpNetStatus) -> bool {
    if (!ppnet_authority_allows(authority, ppnet_cap_inspect())
        || output == (0 as *PpNetStatus)) {
        return false;
    }
    let entries: int = 0;
    let index: int = 0;
    while (index < 8) {
        if (ppnet_arp_active[index]
            && ppnet_arp_expires[index] >= ppnet_port_now_ms()) {
            entries = entries + 1;
        }
        index = index + 1;
    }
    output.initialized = ppnet_initialized_value;
    output.mac = ppnet_mac_value;
    output.transmitted = ppnet_transmitted_value;
    output.received = ppnet_received_value;
    output.dropped = ppnet_dropped_value;
    output.arp_entries = entries as u64;
    return true;
}
