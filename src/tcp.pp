extern fn ppnet_uip_configure(mac: u64, local_ip: u32,
    netmask: u32, gateway: u32) -> int;
extern fn ppnet_uip_connect(destination: u32, port: int) -> int;
extern fn ppnet_uip_send(source: u64, size: int) -> int;
extern fn ppnet_uip_receive(destination: u64, capacity: int) -> int;
extern fn ppnet_uip_poll() -> int;
extern fn ppnet_uip_request_close() -> int;
extern fn ppnet_uip_abort();
extern fn ppnet_uip_connected() -> int;
extern fn ppnet_uip_closed() -> int;
extern fn ppnet_uip_timed_out() -> int;
extern fn ppnet_uip_last_error() -> int;
extern fn ppnet_uip_tx_queued() -> int;
extern fn ppnet_uip_rx_queued() -> int;
extern fn ppnet_uip_contract_selftest() -> int;

static ppnet_tcp_ready: bool;
static ppnet_tcp_open: bool;

fn ppnet_tcp_init(authority: *PpNetAuthority) -> int {
    if (!ppnet_authority_allows(authority,
            ppnet_cap_send() | ppnet_cap_receive())) {
        return ppnet_error_denied();
    }
    if (!ppnet_initialized_value || ppnet_tcp_open) {
        return ppnet_error_state();
    }
    let result: int = ppnet_uip_configure(ppnet_mac_value,
        ppnet_config_value.local_ipv4, ppnet_config_value.netmask,
        ppnet_config_value.gateway_ipv4);
    if (result != 0) { return ppnet_error_port(); }
    ppnet_tcp_ready = true;
    return 0;
}

fn ppnet_tcp_connect(authority: *PpNetAuthority, destination: u32,
    port: int, timeout_ms: int) -> int {
    if (!ppnet_authority_allows(authority,
            ppnet_cap_send() | ppnet_cap_receive())) {
        return ppnet_error_denied();
    }
    if (!ppnet_tcp_ready || ppnet_tcp_open || destination == (0 as u32)
        || port < 1 || port > 65535 || timeout_ms < 1 || timeout_ms > 30000) {
        return ppnet_error_invalid();
    }
    if (ppnet_uip_connect(destination, port) != 0) {
        return ppnet_error_state();
    }
    ppnet_tcp_open = true;
    let deadline: u64 = ppnet_port_now_ms() + (timeout_ms as u64);
    while (ppnet_port_now_ms() <= deadline) {
        let result: int = ppnet_uip_poll();
        if (ppnet_uip_connected() == 1) { return 0; }
        if (result < 0 || ppnet_uip_closed() == 1) {
            ppnet_uip_abort();
            ppnet_tcp_open = false;
            return ppnet_error_port();
        }
        ppnet_port_idle();
    }
    ppnet_uip_abort();
    ppnet_tcp_open = false;
    return ppnet_error_timeout();
}

fn ppnet_tcp_send(authority: *PpNetAuthority, source: u64,
    size: int, timeout_ms: int) -> int {
    if (!ppnet_authority_allows(authority, ppnet_cap_send())) {
        return ppnet_error_denied();
    }
    if (!ppnet_tcp_open || size < 0 || (size > 0 && source == (0 as u64))
        || timeout_ms < 1 || timeout_ms > 30000) {
        return ppnet_error_invalid();
    }
    let queued: int = ppnet_uip_send(source, size);
    if (queued != size) { return ppnet_error_port(); }
    let deadline: u64 = ppnet_port_now_ms() + (timeout_ms as u64);
    while (ppnet_port_now_ms() <= deadline) {
        let result: int = ppnet_uip_poll();
        if (ppnet_uip_tx_queued() == 0) { return size; }
        if (result < 0 || ppnet_uip_closed() == 1) { return ppnet_error_port(); }
        ppnet_port_idle();
    }
    return ppnet_error_timeout();
}

fn ppnet_tcp_receive(authority: *PpNetAuthority, destination: u64,
    capacity: int, timeout_ms: int) -> int {
    if (!ppnet_authority_allows(authority, ppnet_cap_receive())) {
        return ppnet_error_denied();
    }
    if (!ppnet_tcp_open || capacity < 0
        || (capacity > 0 && destination == (0 as u64))
        || timeout_ms < 1 || timeout_ms > 30000) {
        return ppnet_error_invalid();
    }
    let deadline: u64 = ppnet_port_now_ms() + (timeout_ms as u64);
    while (ppnet_port_now_ms() <= deadline) {
        let size: int = ppnet_uip_receive(destination, capacity);
        if (size > 0) { return size; }
        let result: int = ppnet_uip_poll();
        if (ppnet_uip_rx_queued() > 0) {
            return ppnet_uip_receive(destination, capacity);
        }
        if (result < 0) { return ppnet_error_port(); }
        if (ppnet_uip_closed() == 1) { return 0; }
        ppnet_port_idle();
    }
    return ppnet_error_timeout();
}

fn ppnet_tcp_close(authority: *PpNetAuthority, timeout_ms: int) -> int {
    if (!ppnet_authority_allows(authority, ppnet_cap_send())) {
        return ppnet_error_denied();
    }
    if (!ppnet_tcp_open || timeout_ms < 1 || timeout_ms > 30000) {
        return ppnet_error_invalid();
    }
    ppnet_uip_request_close();
    let deadline: u64 = ppnet_port_now_ms() + (timeout_ms as u64);
    while (ppnet_port_now_ms() <= deadline) {
        let result: int = ppnet_uip_poll();
        if (ppnet_uip_closed() == 1) {
            ppnet_uip_abort();
            ppnet_tcp_open = false;
            return 0;
        }
        if (result < 0) { break; }
        ppnet_port_idle();
    }
    ppnet_uip_abort();
    ppnet_tcp_open = false;
    return ppnet_error_timeout();
}

fn ppnet_tcp_abort() {
    ppnet_uip_abort();
    ppnet_tcp_open = false;
}
