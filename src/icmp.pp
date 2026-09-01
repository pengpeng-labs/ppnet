fn ppnet_icmp_process(authority: *PpNetAuthority, source: u32,
    payload: u64, size: int) -> int {
    if (size < 8 || ppnet_checksum(payload, size) != 0) {
        return ppnet_error_protocol();
    }
    let kind: int = volatile_load8(payload) as int;
    let code: int = volatile_load8(payload + (1 as u64)) as int;
    if (code != 0) { return ppnet_error_protocol(); }
    let identifier: int = ppnet_load_be16(payload + (4 as u64));
    let sequence: int = ppnet_load_be16(payload + (6 as u64));
    if (kind == 0 && identifier == ppnet_ping_identifier
        && sequence == ppnet_ping_sequence && source == ppnet_ping_target) {
        ppnet_ping_ready = true;
        return 1;
    }
    if (kind == 8 && ppnet_authority_allows(authority, ppnet_cap_send())) {
        if (size > 1480) { return ppnet_error_protocol(); }
        let response: u64 = ptr_to_int(&ppnet_payload[0]);
        ppnet_copy(response, payload, size);
        volatile_store8(response, 0 as u8);
        ppnet_store_be16(response + (2 as u64), 0);
        ppnet_store_be16(response + (2 as u64), ppnet_checksum(response, size));
        return ppnet_ipv4_send(authority, source, 1, response, size);
    }
    return 0;
}

fn ppnet_ping(authority: *PpNetAuthority, destination: u32,
    timeout_ms: int) -> int {
    if (!ppnet_authority_allows(authority,
            ppnet_cap_send() | ppnet_cap_receive())) {
        return ppnet_error_denied();
    }
    if (!ppnet_initialized_value || destination == (0 as u32)
        || timeout_ms < 1 || timeout_ms > 10000) {
        return ppnet_error_invalid();
    }
    ppnet_ping_sequence = (ppnet_ping_sequence + 1) & 65535;
    ppnet_ping_target = destination;
    ppnet_ping_ready = false;
    let payload: u64 = ptr_to_int(&ppnet_payload[0]);
    ppnet_zero(payload, 8);
    volatile_store8(payload, 8 as u8);
    ppnet_store_be16(payload + (4 as u64), ppnet_ping_identifier);
    ppnet_store_be16(payload + (6 as u64), ppnet_ping_sequence);
    ppnet_store_be16(payload + (2 as u64), ppnet_checksum(payload, 8));
    let sent: int = ppnet_ipv4_send(authority, destination, 1, payload, 8);
    if (sent < 0) { return sent; }
    let deadline: u64 = ppnet_port_now_ms() + (timeout_ms as u64);
    while (ppnet_port_now_ms() <= deadline) {
        let result: int = ppnet_poll(authority);
        if (ppnet_ping_ready) { return 0; }
        if (result == ppnet_error_port()) { return result; }
        ppnet_port_idle();
    }
    return ppnet_error_timeout();
}
