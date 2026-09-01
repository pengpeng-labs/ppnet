import "@oscore/src/oscore.pp";

static ppnet_oscore_principal: OsCorePrincipal;
static ppnet_oscore_mac: [6]u8;
static ppnet_oscore_ready: bool;

fn ppnet_oscore_port_init(principal: OsCorePrincipal) -> bool {
    ppnet_oscore_principal = principal;
    ppnet_oscore_ready = oscore_packet_mac(&ppnet_oscore_principal,
        ptr_to_int(&ppnet_oscore_mac[0]), 6) == 6;
    return ppnet_oscore_ready;
}

fn ppnet_port_mac() -> u64 {
    if (!ppnet_oscore_ready) { return 0 as u64; }
    return ppnet_load_mac(ptr_to_int(&ppnet_oscore_mac[0]));
}

fn ppnet_port_send(source: u64, size: int) -> int {
    if (!ppnet_oscore_ready) { return -1; }
    return oscore_packet_send(&ppnet_oscore_principal, source, size);
}

fn ppnet_port_receive(destination: u64, capacity: int) -> int {
    if (!ppnet_oscore_ready) { return -1; }
    return oscore_packet_receive(&ppnet_oscore_principal,
        destination, capacity);
}

fn ppnet_port_now_ms() -> u64 {
    if (!ppnet_oscore_ready) { return 0 as u64; }
    return oscore_clock_monotonic_ns(&ppnet_oscore_principal)
        / (1000000 as u64);
}

fn ppnet_port_idle() {
    if (ppnet_oscore_ready) { oscore_run_once(); }
}
