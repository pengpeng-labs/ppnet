static ppnet_test_receive_frame: [1526]u8;
static ppnet_test_sent_frame: [1526]u8;
static ppnet_test_receive_size: int;
static ppnet_test_sent_size: int;
static ppnet_test_now: u64;

fn ppnet_port_mac() -> u64 {
    return ((0x5254 as u64) << (32 as u64)) | (0x00123456 as u64);
}

fn ppnet_test_peer_mac() -> u64 {
    return ((0x5254 as u64) << (32 as u64)) | (0x00ABCDEF as u64);
}
fn ppnet_port_now_ms() -> u64 { return ppnet_test_now; }
fn ppnet_port_idle() { ppnet_test_now = ppnet_test_now + (10 as u64); }

fn ppnet_test_copy(destination: u64, source: u64, size: int) {
    let index: int = 0;
    while (index < size) {
        volatile_store8(destination + (index as u64),
            volatile_load8(source + (index as u64)));
        index = index + 1;
    }
}

fn ppnet_port_send(source: u64, size: int) -> int {
    if (source == (0 as u64) || size < 14 || size > 1526) { return -1; }
    ppnet_test_copy(ptr_to_int(&ppnet_test_sent_frame[0]), source, size);
    ppnet_test_sent_size = size;
    if (size == 42 && ppnet_load_be16(source + (12 as u64)) == 0x0806
        && ppnet_load_be16(source + (20 as u64)) == 1) {
        let response: u64 = ptr_to_int(&ppnet_test_receive_frame[0]);
        ppnet_zero(response, 42);
        let peer_mac: u64 = ppnet_test_peer_mac();
        ppnet_store_mac(response, ppnet_port_mac());
        ppnet_store_mac(response + (6 as u64), peer_mac);
        ppnet_store_be16(response + (12 as u64), 0x0806);
        ppnet_store_be16(response + (14 as u64), 1);
        ppnet_store_be16(response + (16 as u64), 0x0800);
        volatile_store8(response + (18 as u64), 6 as u8);
        volatile_store8(response + (19 as u64), 4 as u8);
        ppnet_store_be16(response + (20 as u64), 2);
        ppnet_store_mac(response + (22 as u64), peer_mac);
        ppnet_store_be32(response + (28 as u64),
            ppnet_load_be32(source + (38 as u64)));
        ppnet_store_mac(response + (32 as u64), ppnet_port_mac());
        ppnet_store_be32(response + (38 as u64),
            ppnet_load_be32(source + (28 as u64)));
        ppnet_test_receive_size = 42;
    } else if (size >= 42 && ppnet_load_be16(source + (12 as u64)) == 0x0800
        && volatile_load8(source + (23 as u64)) == (1 as u8)
        && volatile_load8(source + (34 as u64)) == (8 as u8)) {
        let response: u64 = ptr_to_int(&ppnet_test_receive_frame[0]);
        ppnet_test_copy(response, source, size);
        ppnet_store_mac(response, ppnet_port_mac());
        ppnet_store_mac(response + (6 as u64), ppnet_test_peer_mac());
        let source_ip: u32 = ppnet_load_be32(source + (26 as u64));
        let destination_ip: u32 = ppnet_load_be32(source + (30 as u64));
        ppnet_store_be32(response + (26 as u64), destination_ip);
        ppnet_store_be32(response + (30 as u64), source_ip);
        ppnet_store_be16(response + (24 as u64), 0);
        ppnet_store_be16(response + (24 as u64),
            ppnet_checksum(response + (14 as u64), 20));
        volatile_store8(response + (34 as u64), 0 as u8);
        ppnet_store_be16(response + (36 as u64), 0);
        ppnet_store_be16(response + (36 as u64),
            ppnet_checksum(response + (34 as u64), size - 34));
        ppnet_test_receive_size = size;
    } else if (size >= 54 && ppnet_load_be16(source + (12 as u64)) == 0x0800
        && volatile_load8(source + (23 as u64)) == (17 as u8)
        && ppnet_load_be16(source + (36 as u64)) == 53) {
        let request_dns_size: int = ppnet_load_be16(source + (38 as u64)) - 8;
        let response_dns_size: int = request_dns_size + 16;
        let response_size: int = 42 + response_dns_size;
        let response: u64 = ptr_to_int(&ppnet_test_receive_frame[0]);
        ppnet_zero(response, response_size);
        ppnet_store_mac(response, ppnet_port_mac());
        ppnet_store_mac(response + (6 as u64), ppnet_test_peer_mac());
        ppnet_store_be16(response + (12 as u64), 0x0800);
        volatile_store8(response + (14 as u64), 0x45 as u8);
        ppnet_store_be16(response + (16 as u64), 20 + 8 + response_dns_size);
        ppnet_store_be16(response + (18 as u64), 2);
        ppnet_store_be16(response + (20 as u64), 0x4000);
        volatile_store8(response + (22 as u64), 64 as u8);
        volatile_store8(response + (23 as u64), 17 as u8);
        ppnet_store_be32(response + (26 as u64),
            ppnet_load_be32(source + (30 as u64)));
        ppnet_store_be32(response + (30 as u64),
            ppnet_load_be32(source + (26 as u64)));
        ppnet_store_be16(response + (24 as u64),
            ppnet_checksum(response + (14 as u64), 20));
        ppnet_store_be16(response + (34 as u64), 53);
        ppnet_store_be16(response + (36 as u64),
            ppnet_load_be16(source + (34 as u64)));
        ppnet_store_be16(response + (38 as u64), 8 + response_dns_size);
        ppnet_test_copy(response + (42 as u64), source + (42 as u64),
            request_dns_size);
        ppnet_store_be16(response + (44 as u64), 0x8180);
        ppnet_store_be16(response + (48 as u64), 1);
        let answer: u64 = response + ((42 + request_dns_size) as u64);
        ppnet_store_be16(answer, 0xC00C);
        ppnet_store_be16(answer + (2 as u64), 1);
        ppnet_store_be16(answer + (4 as u64), 1);
        ppnet_store_be32(answer + (6 as u64), 60 as u32);
        ppnet_store_be16(answer + (10 as u64), 4);
        ppnet_store_be32(answer + (12 as u64), 0x01020304 as u32);
        ppnet_test_receive_size = response_size;
    }
    return size;
}

fn ppnet_port_receive(destination: u64, capacity: int) -> int {
    if (ppnet_test_receive_size == 0) { return 0; }
    if (destination == (0 as u64) || capacity < ppnet_test_receive_size) {
        return -1;
    }
    let size: int = ppnet_test_receive_size;
    ppnet_test_copy(destination, ptr_to_int(&ppnet_test_receive_frame[0]), size);
    ppnet_test_receive_size = 0;
    return size;
}

fn ppnet_test_reset() {
    ppnet_test_receive_size = 0;
    ppnet_test_sent_size = 0;
    ppnet_test_now = 1000 as u64;
    ppnet_zero(ptr_to_int(&ppnet_test_receive_frame[0]), 1526);
    ppnet_zero(ptr_to_int(&ppnet_test_sent_frame[0]), 1526);
}

fn ppnet_test_queue_short() {
    ppnet_test_receive_size = 8;
}

fn ppnet_test_queue_bad_ipv4() {
    let frame: u64 = ptr_to_int(&ppnet_test_receive_frame[0]);
    ppnet_zero(frame, 34);
    ppnet_store_mac(frame, ppnet_port_mac());
    ppnet_store_mac(frame + (6 as u64), ppnet_test_peer_mac());
    ppnet_store_be16(frame + (12 as u64), 0x0800);
    volatile_store8(frame + (14 as u64), 0x45 as u8);
    ppnet_store_be16(frame + (16 as u64), 20);
    volatile_store8(frame + (22 as u64), 64 as u8);
    volatile_store8(frame + (23 as u64), 1 as u8);
    ppnet_store_be32(frame + (26 as u64), 0x08080808 as u32);
    ppnet_store_be32(frame + (30 as u64), 0x0A00020F as u32);
    ppnet_test_receive_size = 34;
}

fn ppnet_test_bad_dns() -> int {
    let message: u64 = ptr_to_int(&ppnet_test_receive_frame[0]);
    ppnet_zero(message, 12);
    ppnet_dns_ready = true;
    ppnet_store_be16(message, ppnet_dns_transaction);
    ppnet_store_be16(message + (2 as u64), 0x8000);
    ppnet_store_be16(message + (4 as u64), 1);
    ppnet_store_be16(message + (6 as u64), 17);
    let result: int = ppnet_dns_process(message, 12);
    ppnet_dns_ready = false;
    return result;
}
