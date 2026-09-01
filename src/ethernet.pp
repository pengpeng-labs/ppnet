fn ppnet_ethernet_write(address: u64, destination: u64, ether_type: int) {
    ppnet_store_mac(address, destination);
    ppnet_store_mac(address + (6 as u64), ppnet_mac_value);
    ppnet_store_be16(address + (12 as u64), ether_type);
}

fn ppnet_ethernet_accept(address: u64) -> bool {
    let destination: u64 = ppnet_load_mac(address);
    return destination == ppnet_mac_value
        || destination == ppnet_mac_broadcast();
}

fn ppnet_send_frame(authority: *PpNetAuthority, size: int) -> int {
    if (!ppnet_authority_allows(authority, ppnet_cap_send())) {
        return ppnet_error_denied();
    }
    if (!ppnet_initialized_value || size < 14 || size > 1526) {
        return ppnet_error_state();
    }
    let sent: int = ppnet_port_send(ptr_to_int(&ppnet_frame[0]), size);
    if (sent != size) { return ppnet_error_port(); }
    ppnet_transmitted_value = ppnet_transmitted_value + (1 as u64);
    return sent;
}
