extern fn ppnet_tls_configure_trust(anchors: u64, count: int) -> int;
extern fn ppnet_tls_begin(host: u64, host_size: int) -> int;
extern fn ppnet_tls_state() -> int;
extern fn ppnet_tls_send_record(size: *int) -> u64;
extern fn ppnet_tls_send_record_ack(size: int);
extern fn ppnet_tls_receive_record(capacity: *int) -> u64;
extern fn ppnet_tls_receive_record_ack(size: int);
extern fn ppnet_tls_send_application(capacity: *int) -> u64;
extern fn ppnet_tls_send_application_ack(size: int);
extern fn ppnet_tls_receive_application(size: *int) -> u64;
extern fn ppnet_tls_receive_application_ack(size: int);
extern fn ppnet_tls_flush();
extern fn ppnet_tls_last_error() -> int;
extern fn ppnet_tls_end();

static ppnet_tls_ready: bool;
static ppnet_tls_open: bool;

fn ppnet_tls_configure(authority: *PpNetAuthority,
    anchors: u64, count: int) -> int {
    if (!ppnet_authority_allows(authority, ppnet_cap_inspect())) {
        return ppnet_error_denied();
    }
    if (ppnet_tls_open || anchors == (0 as u64) || count < 1 || count > 32) {
        return ppnet_error_invalid();
    }
    if (ppnet_tls_configure_trust(anchors, count) != 0) {
        return ppnet_error_port();
    }
    ppnet_tls_ready = true;
    return 0;
}

fn ppnet_tls_pump(authority: *PpNetAuthority, desired: int,
    timeout_ms: int) -> int {
    let deadline: u64 = ppnet_port_now_ms() + (timeout_ms as u64);
    while (ppnet_port_now_ms() <= deadline) {
        let state: int = ppnet_tls_state();
        if ((state & desired) != 0) { return 0; }
        if ((state & 1) != 0) { return ppnet_error_protocol(); }
        let progress: bool = false;
        if ((state & 2) != 0) {
            let size: int = 0;
            let buffer: u64 = ppnet_tls_send_record(&size);
            if (buffer == (0 as u64) || size < 1
                || ppnet_tcp_send(authority, buffer, size, 1000) != size) {
                return ppnet_error_port();
            }
            ppnet_tls_send_record_ack(size);
            progress = true;
        }
        if ((state & 4) != 0) {
            let capacity: int = 0;
            let buffer: u64 = ppnet_tls_receive_record(&capacity);
            if (buffer == (0 as u64) || capacity < 1) {
                return ppnet_error_protocol();
            }
            let received: int = ppnet_tcp_receive(authority,
                buffer, capacity, 100);
            if (received > 0) {
                ppnet_tls_receive_record_ack(received);
                progress = true;
            } else if (received != ppnet_error_timeout()) {
                return ppnet_error_port();
            }
        }
        let current: int = ppnet_tls_state();
        if ((current & desired) != 0) { return 0; }
        if ((current & 1) != 0) { return ppnet_error_protocol(); }
        if (!progress) { ppnet_port_idle(); }
    }
    return ppnet_error_timeout();
}

fn ppnet_tls_connect(authority: *PpNetAuthority, destination: u32,
    port: int, host: str, timeout_ms: int) -> int {
    if (!ppnet_tls_ready || ppnet_tls_open || len(host) < (1 as u64)
        || len(host) > (253 as u64) || timeout_ms < 1 || timeout_ms > 30000) {
        return ppnet_error_invalid();
    }
    let result: int = ppnet_tcp_connect(authority,
        destination, port, timeout_ms);
    if (result != 0) { return result; }
    if (ppnet_tls_begin(ptr_to_int(host), len(host) as int) != 0) {
        ppnet_tcp_abort();
        return ppnet_error_protocol();
    }
    ppnet_tls_open = true;
    let handshake: int = ppnet_tls_pump(authority, 8, timeout_ms);
    if (handshake != 0) {
        ppnet_tls_end();
        ppnet_tcp_abort();
        ppnet_tls_open = false;
    }
    return handshake;
}

fn ppnet_tls_send(authority: *PpNetAuthority, source: u64,
    size: int, timeout_ms: int) -> int {
    if (!ppnet_tls_open || size < 0 || (size > 0 && source == (0 as u64))) {
        return ppnet_error_invalid();
    }
    let offset: int = 0;
    while (offset < size) {
        if (ppnet_tls_pump(authority, 8, timeout_ms) != 0) {
            return ppnet_error_protocol();
        }
        let capacity: int = 0;
        let buffer: u64 = ppnet_tls_send_application(&capacity);
        if (buffer == (0 as u64) || capacity < 1) {
            return ppnet_error_protocol();
        }
        let count: int = size - offset;
        if (count > capacity) { count = capacity; }
        ppnet_copy(buffer, source + (offset as u64), count);
        ppnet_tls_send_application_ack(count);
        ppnet_tls_flush();
        if (ppnet_tls_pump(authority, 8 | 16, timeout_ms) != 0) {
            return ppnet_error_protocol();
        }
        offset = offset + count;
    }
    return size;
}

fn ppnet_tls_receive(authority: *PpNetAuthority, destination: u64,
    capacity: int, timeout_ms: int) -> int {
    if (!ppnet_tls_open || capacity < 0
        || (capacity > 0 && destination == (0 as u64))) {
        return ppnet_error_invalid();
    }
    let result: int = ppnet_tls_pump(authority, 16, timeout_ms);
    if (result != 0) { return result; }
    let size: int = 0;
    let buffer: u64 = ppnet_tls_receive_application(&size);
    if (buffer == (0 as u64) || size < 0) { return ppnet_error_protocol(); }
    if (size > capacity) { size = capacity; }
    ppnet_copy(destination, buffer, size);
    ppnet_tls_receive_application_ack(size);
    return size;
}

fn ppnet_tls_close() {
    if (ppnet_tls_open) {
        ppnet_tls_end();
        ppnet_tcp_abort();
        ppnet_tls_open = false;
    }
}

fn ppnet_tls_error() -> int { return ppnet_tls_last_error(); }
