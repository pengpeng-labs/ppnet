fn ppnet_ipv4_send(authority: *PpNetAuthority, destination: u32,
    protocol: int, payload: u64, payload_size: int) -> int {
    if (!ppnet_authority_allows(authority, ppnet_cap_send())) {
        return ppnet_error_denied();
    }
    if (!ppnet_initialized_value || destination == (0 as u32)
        || protocol < 1 || protocol > 255 || payload_size < 0
        || payload_size > 1480
        || (payload_size > 0 && payload == (0 as u64))) {
        return ppnet_error_invalid();
    }
    let destination_mac: u64 = ppnet_arp_resolve(authority, destination, 1000);
    if (destination_mac == (0 as u64)) { return ppnet_error_timeout(); }
    let frame: u64 = ptr_to_int(&ppnet_frame[0]);
    ppnet_zero(frame, 14 + 20 + payload_size);
    ppnet_ethernet_write(frame, destination_mac, 0x0800);
    let header: u64 = frame + (14 as u64);
    volatile_store8(header, 0x45 as u8);
    volatile_store8(header + (1 as u64), 0 as u8);
    ppnet_store_be16(header + (2 as u64), 20 + payload_size);
    ppnet_store_be16(header + (4 as u64), ppnet_ipv4_identifier);
    ppnet_ipv4_identifier = (ppnet_ipv4_identifier + 1) & 65535;
    ppnet_store_be16(header + (6 as u64), 0x4000);
    volatile_store8(header + (8 as u64), ppnet_config_value.ttl as u8);
    volatile_store8(header + (9 as u64), protocol as u8);
    ppnet_store_be32(header + (12 as u64), ppnet_config_value.local_ipv4);
    ppnet_store_be32(header + (16 as u64), destination);
    ppnet_store_be16(header + (10 as u64), ppnet_checksum(header, 20));
    ppnet_copy(header + (20 as u64), payload, payload_size);
    let sent: int = ppnet_send_frame(authority, 34 + payload_size);
    if (sent < 0) { return sent; }
    return payload_size;
}

fn ppnet_ipv4_process(authority: *PpNetAuthority, frame: u64, size: int) -> int {
    if (size < 34) { return ppnet_error_protocol(); }
    let header: u64 = frame + (14 as u64);
    if (volatile_load8(header) != (0x45 as u8)) {
        return ppnet_error_protocol();
    }
    let total: int = ppnet_load_be16(header + (2 as u64));
    let fragment: int = ppnet_load_be16(header + (6 as u64));
    if (total < 20 || total > 1500 || 14 + total > size
        || (fragment & 0xBFFF) != 0 || ppnet_checksum(header, 20) != 0
        || ppnet_load_be32(header + (16 as u64))
            != ppnet_config_value.local_ipv4) {
        return ppnet_error_protocol();
    }
    let protocol: int = volatile_load8(header + (9 as u64)) as int;
    let source: u32 = ppnet_load_be32(header + (12 as u64));
    if (source == (0 as u32) || source == (0xFFFFFFFF as u32)) {
        return ppnet_error_protocol();
    }
    let payload: u64 = header + (20 as u64);
    let payload_size: int = total - 20;
    if (protocol == 1) {
        return ppnet_icmp_process(authority, source, payload, payload_size);
    }
    if (protocol == 17) {
        return ppnet_udp_process(authority, source, payload, payload_size);
    }
    return 0;
}
