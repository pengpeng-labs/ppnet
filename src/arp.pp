fn ppnet_arp_cache(ip: u32, mac: u64) {
    if (ip == (0 as u32) || mac == (0 as u64)
        || mac > ppnet_mac_mask() || mac == ppnet_mac_broadcast()
        || ((mac >> (40 as u64)) & (1 as u64)) != (0 as u64)) {
        return;
    }
    let slot: int = -1;
    let index: int = 0;
    while (index < 8) {
        if (ppnet_arp_active[index] && ppnet_arp_ip[index] == ip) {
            slot = index;
            index = 8;
        } else {
            index = index + 1;
        }
    }
    if (slot < 0) {
        slot = ppnet_arp_next;
        ppnet_arp_next = (ppnet_arp_next + 1) % 8;
    }
    ppnet_arp_active[slot] = true;
    ppnet_arp_ip[slot] = ip;
    ppnet_arp_mac[slot] = mac;
    ppnet_arp_expires[slot] = ppnet_port_now_ms() + (60000 as u64);
}

fn ppnet_arp_lookup(ip: u32) -> u64 {
    let now: u64 = ppnet_port_now_ms();
    let index: int = 0;
    while (index < 8) {
        if (ppnet_arp_active[index] && ppnet_arp_ip[index] == ip) {
            if (ppnet_arp_expires[index] >= now) { return ppnet_arp_mac[index]; }
            ppnet_arp_active[index] = false;
        }
        index = index + 1;
    }
    return 0 as u64;
}

fn ppnet_arp_send_request(authority: *PpNetAuthority, target: u32) -> int {
    let frame: u64 = ptr_to_int(&ppnet_frame[0]);
    ppnet_zero(frame, 42);
    ppnet_ethernet_write(frame, ppnet_mac_broadcast(), 0x0806);
    ppnet_store_be16(frame + (14 as u64), 1);
    ppnet_store_be16(frame + (16 as u64), 0x0800);
    volatile_store8(frame + (18 as u64), 6 as u8);
    volatile_store8(frame + (19 as u64), 4 as u8);
    ppnet_store_be16(frame + (20 as u64), 1);
    ppnet_store_mac(frame + (22 as u64), ppnet_mac_value);
    ppnet_store_be32(frame + (28 as u64), ppnet_config_value.local_ipv4);
    ppnet_store_be32(frame + (38 as u64), target);
    return ppnet_send_frame(authority, 42);
}

fn ppnet_arp_process(authority: *PpNetAuthority, frame: u64, size: int) -> int {
    if (size < 42 || ppnet_load_be16(frame + (14 as u64)) != 1
        || ppnet_load_be16(frame + (16 as u64)) != 0x0800
        || volatile_load8(frame + (18 as u64)) != (6 as u8)
        || volatile_load8(frame + (19 as u64)) != (4 as u8)) {
        return ppnet_error_protocol();
    }
    let operation: int = ppnet_load_be16(frame + (20 as u64));
    let sender_mac: u64 = ppnet_load_mac(frame + (22 as u64));
    let sender_ip: u32 = ppnet_load_be32(frame + (28 as u64));
    let target_mac: u64 = ppnet_load_mac(frame + (32 as u64));
    let target_ip: u32 = ppnet_load_be32(frame + (38 as u64));
    if ((operation != 1 && operation != 2)
        || ppnet_load_mac(frame + (6 as u64)) != sender_mac) {
        return ppnet_error_protocol();
    }
    if (operation == 2 && (target_ip != ppnet_config_value.local_ipv4
        || target_mac != ppnet_mac_value)) {
        return 0;
    }
    if (sender_ip != (0 as u32)) { ppnet_arp_cache(sender_ip, sender_mac); }
    if (operation == 1 && target_ip == ppnet_config_value.local_ipv4
        && ppnet_authority_allows(authority, ppnet_cap_send())) {
        let output: u64 = ptr_to_int(&ppnet_frame[0]);
        ppnet_zero(output, 42);
        ppnet_ethernet_write(output, sender_mac, 0x0806);
        ppnet_store_be16(output + (14 as u64), 1);
        ppnet_store_be16(output + (16 as u64), 0x0800);
        volatile_store8(output + (18 as u64), 6 as u8);
        volatile_store8(output + (19 as u64), 4 as u8);
        ppnet_store_be16(output + (20 as u64), 2);
        ppnet_store_mac(output + (22 as u64), ppnet_mac_value);
        ppnet_store_be32(output + (28 as u64), ppnet_config_value.local_ipv4);
        ppnet_store_mac(output + (32 as u64), sender_mac);
        ppnet_store_be32(output + (38 as u64), sender_ip);
        return ppnet_send_frame(authority, 42);
    }
    return 1;
}

fn ppnet_next_hop(destination: u32) -> u32 {
    if ((destination & ppnet_config_value.netmask)
        == (ppnet_config_value.local_ipv4 & ppnet_config_value.netmask)) {
        return destination;
    }
    return ppnet_config_value.gateway_ipv4;
}

fn ppnet_arp_resolve(authority: *PpNetAuthority, destination: u32,
    timeout_ms: int) -> u64 {
    if (!ppnet_authority_allows(authority,
            ppnet_cap_send() | ppnet_cap_receive())
        || !ppnet_initialized_value || destination == (0 as u32)
        || timeout_ms < 1 || timeout_ms > 10000) {
        return 0 as u64;
    }
    let target: u32 = ppnet_next_hop(destination);
    let cached: u64 = ppnet_arp_lookup(target);
    if (cached != (0 as u64)) { return cached; }
    if (ppnet_arp_send_request(authority, target) < 0) { return 0 as u64; }
    let deadline: u64 = ppnet_port_now_ms() + (timeout_ms as u64);
    while (ppnet_port_now_ms() <= deadline) {
        ppnet_poll(authority);
        let resolved: u64 = ppnet_arp_lookup(target);
        if (resolved != (0 as u64)) { return resolved; }
        ppnet_port_idle();
    }
    return 0 as u64;
}
