fn ppnet_zero(address: u64, size: int) {
    let index: int = 0;
    while (index < size) {
        volatile_store8(address + (index as u64), 0);
        index = index + 1;
    }
}

fn ppnet_copy(destination: u64, source: u64, size: int) {
    let index: int = 0;
    while (index < size) {
        volatile_store8(destination + (index as u64),
            volatile_load8(source + (index as u64)));
        index = index + 1;
    }
}

fn ppnet_load_be16(address: u64) -> int {
    return ((volatile_load8(address) as int) << 8)
        | (volatile_load8(address + (1 as u64)) as int);
}

fn ppnet_store_be16(address: u64, value: int) {
    volatile_store8(address, ((value >> 8) & 255) as u8);
    volatile_store8(address + (1 as u64), (value & 255) as u8);
}

fn ppnet_load_be32(address: u64) -> u32 {
    return ((volatile_load8(address) as u32) << (24 as u32))
        | ((volatile_load8(address + (1 as u64)) as u32) << (16 as u32))
        | ((volatile_load8(address + (2 as u64)) as u32) << (8 as u32))
        | (volatile_load8(address + (3 as u64)) as u32);
}

fn ppnet_store_be32(address: u64, value: u32) {
    volatile_store8(address, ((value >> (24 as u32)) & (255 as u32)) as u8);
    volatile_store8(address + (1 as u64),
        ((value >> (16 as u32)) & (255 as u32)) as u8);
    volatile_store8(address + (2 as u64),
        ((value >> (8 as u32)) & (255 as u32)) as u8);
    volatile_store8(address + (3 as u64), (value & (255 as u32)) as u8);
}

fn ppnet_load_mac(address: u64) -> u64 {
    let value: u64 = 0 as u64;
    let index: int = 0;
    while (index < 6) {
        value = (value << (8 as u64))
            | (volatile_load8(address + (index as u64)) as u64);
        index = index + 1;
    }
    return value;
}

fn ppnet_mac_mask() -> u64 {
    return ((1 as u64) << (48 as u64)) - (1 as u64);
}

fn ppnet_mac_broadcast() -> u64 { return ppnet_mac_mask(); }

fn ppnet_store_mac(address: u64, value: u64) {
    let index: int = 0;
    while (index < 6) {
        let shift: u64 = ((5 - index) * 8) as u64;
        volatile_store8(address + (index as u64),
            ((value >> shift) & (255 as u64)) as u8);
        index = index + 1;
    }
}

fn ppnet_checksum_sum(sum: int, address: u64, size: int) -> int {
    let value: int = sum;
    let index: int = 0;
    while (index < size) {
        value = value + ((volatile_load8(address + (index as u64)) as int) << 8);
        if (index + 1 < size) {
            value = value
                + (volatile_load8(address + ((index + 1) as u64)) as int);
        }
        value = (value & 65535) + (value >> 16);
        index = index + 2;
    }
    return value;
}

fn ppnet_checksum_finish(sum: int) -> int {
    let value: int = sum;
    while (value > 65535) { value = (value & 65535) + (value >> 16); }
    return (65535 - value) & 65535;
}

fn ppnet_checksum(address: u64, size: int) -> int {
    return ppnet_checksum_finish(ppnet_checksum_sum(0, address, size));
}
