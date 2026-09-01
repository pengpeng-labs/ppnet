struct PpNetAuthority {
    owner: u64,
    capabilities: u64,
}

struct PpNetConfig {
    local_ipv4: u32,
    netmask: u32,
    gateway_ipv4: u32,
    dns_ipv4: u32,
    ttl: u64,
}

struct PpNetStatus {
    initialized: bool,
    mac: u64,
    transmitted: u64,
    received: u64,
    dropped: u64,
    arp_entries: u64,
}

fn ppnet_cap_send() -> u64 { return 1 as u64; }
fn ppnet_cap_receive() -> u64 { return 2 as u64; }
fn ppnet_cap_inspect() -> u64 { return 4 as u64; }
fn ppnet_all_capabilities() -> u64 { return 7 as u64; }

fn ppnet_authority(owner: u64, capabilities: u64) -> PpNetAuthority {
    let authority: PpNetAuthority;
    authority.owner = owner;
    authority.capabilities = capabilities & ppnet_all_capabilities();
    return authority;
}

fn ppnet_authority_allows(authority: *PpNetAuthority, required: u64) -> bool {
    return authority != (0 as *PpNetAuthority) && authority.owner != (0 as u64)
        && (authority.capabilities & required) == required;
}

fn ppnet_error_invalid() -> int { return -1; }
fn ppnet_error_denied() -> int { return -2; }
fn ppnet_error_port() -> int { return -3; }
fn ppnet_error_timeout() -> int { return -4; }
fn ppnet_error_protocol() -> int { return -5; }
fn ppnet_error_state() -> int { return -6; }
