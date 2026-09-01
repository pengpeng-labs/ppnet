fn ppnet_poll(authority: *PpNetAuthority) -> int {
    if (!ppnet_authority_allows(authority, ppnet_cap_receive())) {
        return ppnet_error_denied();
    }
    if (!ppnet_initialized_value) { return ppnet_error_state(); }
    let frame: u64 = ptr_to_int(&ppnet_frame[0]);
    let size: int = ppnet_port_receive(frame, 1526);
    if (size < 0) { return ppnet_error_port(); }
    if (size == 0) { return 0; }
    ppnet_received_value = ppnet_received_value + (1 as u64);
    if (size < 14 || size > 1526 || !ppnet_ethernet_accept(frame)) {
        ppnet_dropped_value = ppnet_dropped_value + (1 as u64);
        return ppnet_error_protocol();
    }
    let ether_type: int = ppnet_load_be16(frame + (12 as u64));
    let result: int = 0;
    if (ether_type == 0x0806) {
        result = ppnet_arp_process(authority, frame, size);
    } else if (ether_type == 0x0800) {
        result = ppnet_ipv4_process(authority, frame, size);
    }
    if (result < 0) {
        ppnet_dropped_value = ppnet_dropped_value + (1 as u64);
    }
    return result;
}
