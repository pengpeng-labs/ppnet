static ppnet_dns_message: [512]u8;

fn ppnet_dns_skip_name(message: u64, size: int, offset: int) -> int {
    let position: int = offset;
    let labels: int = 0;
    while (position < size && labels < 128) {
        let length: int = volatile_load8(message + (position as u64)) as int;
        if (length == 0) { return position + 1; }
        if ((length & 0xC0) == 0xC0) {
            if (position + 2 > size) { return -1; }
            let pointer: int = ((length & 0x3F) << 8)
                | (volatile_load8(message + ((position + 1) as u64)) as int);
            if (pointer >= size) { return -1; }
            return position + 2;
        }
        if ((length & 0xC0) != 0 || length > 63
            || position + 1 + length > size) {
            return -1;
        }
        position = position + 1 + length;
        labels = labels + 1;
    }
    return -1;
}

fn ppnet_dns_process(message: u64, size: int) -> int {
    if (!ppnet_dns_ready || message == (0 as u64) || size < 12
        || ppnet_load_be16(message) != ppnet_dns_transaction
        || (ppnet_load_be16(message + (2 as u64)) & 0xFA0F) != 0x8000
        || ppnet_load_be16(message + (4 as u64)) != 1) {
        return ppnet_error_protocol();
    }
    let answers: int = ppnet_load_be16(message + (6 as u64));
    if (answers < 1 || answers > 16) { return ppnet_error_protocol(); }
    let offset: int = ppnet_dns_skip_name(message, size, 12);
    if (offset < 0 || offset + 4 > size) { return ppnet_error_protocol(); }
    if (ppnet_load_be16(message + (offset as u64)) != 1
        || ppnet_load_be16(message + ((offset + 2) as u64)) != 1) {
        return ppnet_error_protocol();
    }
    offset = offset + 4;
    let index: int = 0;
    while (index < answers) {
        offset = ppnet_dns_skip_name(message, size, offset);
        if (offset < 0 || offset + 10 > size) { return ppnet_error_protocol(); }
        let kind: int = ppnet_load_be16(message + (offset as u64));
        let class: int = ppnet_load_be16(message + ((offset + 2) as u64));
        let length: int = ppnet_load_be16(message + ((offset + 8) as u64));
        offset = offset + 10;
        if (length < 0 || offset + length > size) { return ppnet_error_protocol(); }
        if (kind == 1 && class == 1 && length == 4) {
            ppnet_dns_result = ppnet_load_be32(message + (offset as u64));
            ppnet_dns_ready = false;
            return 1;
        }
        offset = offset + length;
        index = index + 1;
    }
    return 0;
}

fn ppnet_dns_encode_name(name: str, destination: u64, capacity: int) -> int {
    let length: int = len(name) as int;
    if (length < 1 || length > 253 || destination == (0 as u64)
        || capacity < length + 2) {
        return ppnet_error_invalid();
    }
    let source: *u8 = ptr_to_int(name) as *u8;
    let input: int = 0;
    let output: int = 0;
    while (input < length) {
        let label_start: int = input;
        while (input < length && source[input] != (46 as u8)) {
            let value: int = source[input] as int;
            let lower: bool = value >= 97 && value <= 122;
            let upper: bool = value >= 65 && value <= 90;
            let digit: bool = value >= 48 && value <= 57;
            if (!lower && !upper && !digit && value != 45) {
                return ppnet_error_invalid();
            }
            input = input + 1;
        }
        let label_length: int = input - label_start;
        if (label_length < 1 || label_length > 63
            || output + 1 + label_length >= capacity) {
            return ppnet_error_invalid();
        }
        volatile_store8(destination + (output as u64), label_length as u8);
        output = output + 1;
        ppnet_copy(destination + (output as u64),
            ptr_to_int(source + label_start), label_length);
        output = output + label_length;
        if (input < length) { input = input + 1; }
    }
    volatile_store8(destination + (output as u64), 0 as u8);
    return output + 1;
}

fn ppnet_dns_resolve(authority: *PpNetAuthority, name: str,
    timeout_ms: int) -> u32 {
    if (!ppnet_authority_allows(authority,
            ppnet_cap_send() | ppnet_cap_receive())
        || !ppnet_initialized_value || ppnet_dns_ready
        || timeout_ms < 1 || timeout_ms > 10000) {
        return 0 as u32;
    }
    let message: u64 = ptr_to_int(&ppnet_dns_message[0]);
    ppnet_zero(message, 512);
    ppnet_dns_transaction = (ppnet_dns_transaction + 1) & 65535;
    ppnet_store_be16(message, ppnet_dns_transaction);
    ppnet_store_be16(message + (2 as u64), 0x0100);
    ppnet_store_be16(message + (4 as u64), 1);
    let name_size: int = ppnet_dns_encode_name(name, message + (12 as u64), 496);
    if (name_size < 0) { return 0 as u32; }
    let size: int = 12 + name_size + 4;
    ppnet_store_be16(message + ((12 + name_size) as u64), 1);
    ppnet_store_be16(message + ((14 + name_size) as u64), 1);
    ppnet_dns_ready = true;
    ppnet_dns_result = 0 as u32;
    let sent: int = ppnet_udp_send(authority, ppnet_config_value.dns_ipv4,
        ppnet_dns_port, 53, message, size);
    if (sent < 0) {
        ppnet_dns_ready = false;
        return 0 as u32;
    }
    let deadline: u64 = ppnet_port_now_ms() + (timeout_ms as u64);
    while (ppnet_port_now_ms() <= deadline) {
        let result: int = ppnet_poll(authority);
        if (!ppnet_dns_ready) { return ppnet_dns_result; }
        if (result == ppnet_error_port()) { break; }
        ppnet_port_idle();
    }
    ppnet_dns_ready = false;
    return 0 as u32;
}
