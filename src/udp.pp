fn ppnet_udp_checksum(source: u32, destination: u32,
    udp: u64, size: int) -> int {
    let sum: int = ((source >> (16 as u32)) & (65535 as u32)) as int;
    sum = sum + (source & (65535 as u32)) as int;
    sum = sum + ((destination >> (16 as u32)) & (65535 as u32)) as int;
    sum = sum + (destination & (65535 as u32)) as int;
    sum = sum + 17 + size;
    return ppnet_checksum_finish(ppnet_checksum_sum(sum, udp, size));
}

fn ppnet_udp_send(authority: *PpNetAuthority, destination: u32,
    source_port: int, destination_port: int, data: u64, size: int) -> int {
    if (source_port < 1 || source_port > 65535 || destination_port < 1
        || destination_port > 65535 || size < 0 || size > 1472
        || (size > 0 && data == (0 as u64))) {
        return ppnet_error_invalid();
    }
    let udp: u64 = ptr_to_int(&ppnet_payload[0]);
    ppnet_zero(udp, 8 + size);
    ppnet_store_be16(udp, source_port);
    ppnet_store_be16(udp + (2 as u64), destination_port);
    ppnet_store_be16(udp + (4 as u64), 8 + size);
    ppnet_copy(udp + (8 as u64), data, size);
    let checksum: int = ppnet_udp_checksum(ppnet_config_value.local_ipv4,
        destination, udp, 8 + size);
    if (checksum == 0) { checksum = 65535; }
    ppnet_store_be16(udp + (6 as u64), checksum);
    let result: int = ppnet_ipv4_send(authority, destination, 17, udp, 8 + size);
    if (result < 0) { return result; }
    return size;
}

fn ppnet_udp_process(authority: *PpNetAuthority, source: u32,
    payload: u64, size: int) -> int {
    if (size < 8) { return ppnet_error_protocol(); }
    let source_port: int = ppnet_load_be16(payload);
    let destination_port: int = ppnet_load_be16(payload + (2 as u64));
    let length: int = ppnet_load_be16(payload + (4 as u64));
    let checksum: int = ppnet_load_be16(payload + (6 as u64));
    if (source_port == 0 || destination_port == 0 || length < 8
        || length > size) {
        return ppnet_error_protocol();
    }
    if (checksum != 0 && ppnet_udp_checksum(source,
            ppnet_config_value.local_ipv4, payload, length) != 0) {
        return ppnet_error_protocol();
    }
    if (source == ppnet_config_value.dns_ipv4 && source_port == 53
        && destination_port == ppnet_dns_port) {
        return ppnet_dns_process(payload + (8 as u64), length - 8);
    }
    return 0;
}
