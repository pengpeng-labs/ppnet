#ifndef PPNET_UIP_ADAPTER_H
#define PPNET_UIP_ADAPTER_H

#include <stdint.h>

enum {
    PPNET_C_EINVAL = -1,
    PPNET_C_EBUSY = -2,
    PPNET_C_ECAPACITY = -3,
    PPNET_C_EPORT = -4,
    PPNET_C_ESTATE = -5
};

int32_t ppnet_uip_configure(uint64_t mac, uint32_t local_ip,
    uint32_t netmask, uint32_t gateway);
int32_t ppnet_uip_connect(uint32_t destination, int32_t port);
int32_t ppnet_uip_send(uint64_t source, int32_t size);
int32_t ppnet_uip_receive(uint64_t destination, int32_t capacity);
int32_t ppnet_uip_poll(void);
int32_t ppnet_uip_request_close(void);
void ppnet_uip_abort(void);
int32_t ppnet_uip_connected(void);
int32_t ppnet_uip_closed(void);
int32_t ppnet_uip_timed_out(void);
int32_t ppnet_uip_last_error(void);
int32_t ppnet_uip_tx_queued(void);
int32_t ppnet_uip_rx_queued(void);
int32_t ppnet_uip_contract_selftest(void);

#endif
