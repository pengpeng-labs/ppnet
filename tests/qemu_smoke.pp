import "../src/ppnet.pp";
import "../src/oscore_port.pp";

fn ppnet_qemu_fail(message: str) {
    oscore_platform_write("PPNET FAIL ");
    oscore_platform_write(message);
    oscore_platform_write("\n");
    osbare_halt();
}

fn osbare_main(boot_info: *OsBareBootInfo) {
    if (!oscore_init(boot_info)) { ppnet_qemu_fail("oscore-init"); }
    let principal: OsCorePrincipal = oscore_principal_root();
    if (!ppnet_oscore_port_init(principal)) { ppnet_qemu_fail("packet-port"); }
    let root: PpNetAuthority = ppnet_authority(1 as u64,
        ppnet_all_capabilities());
    let config: PpNetConfig;
    config.local_ipv4 = 0x0A00020F as u32;
    config.netmask = 0xFFFFFF00 as u32;
    config.gateway_ipv4 = 0x0A000202 as u32;
    config.dns_ipv4 = 0x0A000203 as u32;
    config.ttl = 64 as u64;
    if (ppnet_init(&root, &config) != 0) { ppnet_qemu_fail("init"); }
    if (ppnet_arp_resolve(&root, config.gateway_ipv4, 3000) == (0 as u64)) {
        ppnet_qemu_fail("arp");
    }
    oscore_platform_write("PPNET QEMU ARP PASS\n");
    if (ppnet_ping(&root, config.gateway_ipv4, 3000) != 0) {
        ppnet_qemu_fail("icmp");
    }
    oscore_platform_write("PPNET QEMU ICMP PASS\n");
    oscore_platform_write("PPNET READY\n");
    osbare_halt();
}
