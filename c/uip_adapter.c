#include <stdint.h>
#include <string.h>

#include "uip.h"
#include "uip_arp.h"
#include "uip_adapter.h"

#define PPNET_TCP_QUEUE_CAPACITY 32768
#define PPNET_TCP_RECEIVE_CAPACITY 32768

extern int32_t ppnet_port_send(uint64_t source, int32_t size);
extern int32_t ppnet_port_receive(uint64_t destination, int32_t capacity);
extern uint64_t ppnet_port_now_ms(void);

static uint8_t ppnet_uip_frame[1600];
static uint8_t ppnet_uip_pending[PPNET_TCP_QUEUE_CAPACITY];
static uint8_t ppnet_uip_inflight[UIP_TCP_MSS];
static uint8_t ppnet_uip_receive_data[PPNET_TCP_RECEIVE_CAPACITY];
static int32_t ppnet_uip_pending_size;
static int32_t ppnet_uip_inflight_size;
static int32_t ppnet_uip_receive_head;
static int32_t ppnet_uip_receive_tail;
static int32_t ppnet_uip_receive_full;
static int32_t ppnet_uip_configured;
static int32_t ppnet_uip_session;
static int32_t ppnet_uip_is_connected;
static int32_t ppnet_uip_is_closed;
static int32_t ppnet_uip_is_timed_out;
static int32_t ppnet_uip_close_requested;
static int32_t ppnet_uip_error;
static int32_t ppnet_uip_poll_active;
static uint64_t ppnet_uip_last_periodic;
static uint64_t ppnet_uip_last_arp;
static struct uip_conn *ppnet_uip_connection;

static void ppnet_uip_address(uip_ipaddr_t *output, uint32_t value) {
    uip_ipaddr(output,
        (uint8_t)(value >> 24), (uint8_t)(value >> 16),
        (uint8_t)(value >> 8), (uint8_t)value);
}

static int32_t ppnet_uip_emit(void) {
    if (uip_len == 0) { return 0; }
    int32_t size = (int32_t)uip_len;
    int32_t result = ppnet_port_send((uint64_t)(uintptr_t)uip_buf, size);
    uip_len = 0;
    if (result != size) {
        ppnet_uip_error = PPNET_C_EPORT;
        return PPNET_C_EPORT;
    }
    return 1;
}

static int32_t ppnet_uip_receive_free(void) {
    if (ppnet_uip_receive_full) { return 0; }
    if (ppnet_uip_receive_tail > ppnet_uip_receive_head) {
        return ppnet_uip_receive_tail - ppnet_uip_receive_head;
    }
    return PPNET_TCP_RECEIVE_CAPACITY - ppnet_uip_receive_head
        + ppnet_uip_receive_tail;
}

void ppnet_uip_appcall(void) {
    if (uip_connected()) { ppnet_uip_is_connected = 1; }
    if (uip_timedout()) { ppnet_uip_is_timed_out = 1; }
    if (uip_aborted() || uip_closed() || uip_timedout()) {
        ppnet_uip_is_closed = 1;
        ppnet_uip_connection = 0;
    }
    if (uip_newdata()) {
        int32_t size = (int32_t)uip_datalen();
        int32_t free_size = ppnet_uip_receive_free();
        if (size < 0 || size > free_size) {
            ppnet_uip_error = PPNET_C_ECAPACITY;
            ppnet_uip_is_closed = 1;
            uip_abort();
        } else if (size > 0) {
            int32_t first = size;
            if (first > PPNET_TCP_RECEIVE_CAPACITY - ppnet_uip_receive_head) {
                first = PPNET_TCP_RECEIVE_CAPACITY - ppnet_uip_receive_head;
            }
            memcpy(&ppnet_uip_receive_data[ppnet_uip_receive_head],
                uip_appdata, (size_t)first);
            if (size > first) {
                memcpy(ppnet_uip_receive_data,
                    (const uint8_t *)uip_appdata + first,
                    (size_t)(size - first));
            }
            ppnet_uip_receive_head =
                (ppnet_uip_receive_head + size) % PPNET_TCP_RECEIVE_CAPACITY;
            ppnet_uip_receive_full =
                ppnet_uip_receive_head == ppnet_uip_receive_tail;
        }
    }
    if (uip_acked()) { ppnet_uip_inflight_size = 0; }
    if (uip_rexmit() && ppnet_uip_inflight_size > 0) {
        uip_send(ppnet_uip_inflight, ppnet_uip_inflight_size);
    } else if ((uip_poll() || uip_acked()) && ppnet_uip_inflight_size == 0
        && ppnet_uip_pending_size > 0) {
        int32_t size = ppnet_uip_pending_size;
        if (size > (int32_t)uip_conn->mss) { size = uip_conn->mss; }
        if (size > (int32_t)sizeof(ppnet_uip_inflight)) {
            size = sizeof(ppnet_uip_inflight);
        }
        memcpy(ppnet_uip_inflight, ppnet_uip_pending, (size_t)size);
        if (size < ppnet_uip_pending_size) {
            memmove(ppnet_uip_pending, ppnet_uip_pending + size,
                (size_t)(ppnet_uip_pending_size - size));
        }
        ppnet_uip_pending_size -= size;
        ppnet_uip_inflight_size = size;
        uip_send(ppnet_uip_inflight, size);
    } else if (ppnet_uip_close_requested && ppnet_uip_pending_size == 0
        && ppnet_uip_inflight_size == 0) {
        uip_close();
    }
}

static void ppnet_uip_reset_session(void) {
    ppnet_uip_pending_size = 0;
    ppnet_uip_inflight_size = 0;
    ppnet_uip_receive_head = 0;
    ppnet_uip_receive_tail = 0;
    ppnet_uip_receive_full = 0;
    ppnet_uip_is_connected = 0;
    ppnet_uip_is_closed = 0;
    ppnet_uip_is_timed_out = 0;
    ppnet_uip_close_requested = 0;
    ppnet_uip_error = 0;
    ppnet_uip_poll_active = 0;
    ppnet_uip_connection = 0;
}

int32_t ppnet_uip_configure(uint64_t mac, uint32_t local_ip,
    uint32_t netmask, uint32_t gateway) {
    if (ppnet_uip_session || mac == 0 || mac > UINT64_C(0xFFFFFFFFFFFF)
        || local_ip == 0 || netmask == 0 || gateway == 0) {
        return PPNET_C_EINVAL;
    }
    struct uip_eth_addr ethernet;
    uip_ipaddr_t address;
    int32_t index;
    uip_init();
    uip_arp_init();
    for (index = 0; index < 6; index++) {
        ethernet.addr[index] = (uint8_t)(mac >> ((5 - index) * 8));
    }
    uip_setethaddr(ethernet);
    ppnet_uip_address(&address, local_ip);
    uip_sethostaddr(address);
    ppnet_uip_address(&address, netmask);
    uip_setnetmask(address);
    ppnet_uip_address(&address, gateway);
    uip_setdraddr(address);
    ppnet_uip_reset_session();
    ppnet_uip_last_periodic = ppnet_port_now_ms();
    ppnet_uip_last_arp = ppnet_uip_last_periodic;
    ppnet_uip_configured = 1;
    return 0;
}

int32_t ppnet_uip_connect(uint32_t destination, int32_t port) {
    if (!ppnet_uip_configured || ppnet_uip_session || destination == 0
        || port < 1 || port > 65535) {
        return PPNET_C_ESTATE;
    }
    uip_ipaddr_t address;
    ppnet_uip_reset_session();
    ppnet_uip_address(&address, destination);
    ppnet_uip_connection = uip_connect(&address, htons((uint16_t)port));
    if (ppnet_uip_connection == 0) { return PPNET_C_EBUSY; }
    ppnet_uip_session = 1;
    return 0;
}

int32_t ppnet_uip_send(uint64_t source, int32_t size) {
    if (!ppnet_uip_session || !ppnet_uip_is_connected || ppnet_uip_is_closed) {
        return PPNET_C_ESTATE;
    }
    if (size < 0 || (size > 0 && source == 0)) { return PPNET_C_EINVAL; }
    if (size > PPNET_TCP_QUEUE_CAPACITY - ppnet_uip_pending_size) {
        return PPNET_C_ECAPACITY;
    }
    memcpy(ppnet_uip_pending + ppnet_uip_pending_size,
        (const void *)(uintptr_t)source, (size_t)size);
    ppnet_uip_pending_size += size;
    return size;
}

int32_t ppnet_uip_receive(uint64_t destination, int32_t capacity) {
    if (!ppnet_uip_session || capacity < 0
        || (capacity > 0 && destination == 0)) {
        return PPNET_C_EINVAL;
    }
    uint8_t *output = (uint8_t *)(uintptr_t)destination;
    int32_t size = 0;
    while (size < capacity && (ppnet_uip_receive_full
        || ppnet_uip_receive_head != ppnet_uip_receive_tail)) {
        output[size++] = ppnet_uip_receive_data[ppnet_uip_receive_tail++];
        if (ppnet_uip_receive_tail == PPNET_TCP_RECEIVE_CAPACITY) {
            ppnet_uip_receive_tail = 0;
        }
        ppnet_uip_receive_full = 0;
    }
    return size;
}

int32_t ppnet_uip_poll(void) {
    if (!ppnet_uip_configured) { return PPNET_C_ESTATE; }
    if (ppnet_uip_poll_active) { return PPNET_C_EBUSY; }
    ppnet_uip_poll_active = 1;
    int32_t handled = 0;
    int32_t size = ppnet_port_receive(
        (uint64_t)(uintptr_t)ppnet_uip_frame, sizeof(ppnet_uip_frame));
    if (size < 0) {
        ppnet_uip_error = PPNET_C_EPORT;
        ppnet_uip_poll_active = 0;
        return PPNET_C_EPORT;
    }
    if (size > 0) {
        if (size > (int32_t)sizeof(uip_buf)) { size = sizeof(uip_buf); }
        memcpy(uip_buf, ppnet_uip_frame, (size_t)size);
        uip_len = (u16_t)size;
        if (size < 14) {
            ppnet_uip_error = PPNET_C_EINVAL;
        } else if (ppnet_uip_frame[12] == 0x08
            && ppnet_uip_frame[13] == 0x00) {
            uip_arp_ipin();
            if (uip_len > 0) {
                uip_input();
                if (uip_len > 0) { uip_arp_out(); }
            }
            if (ppnet_uip_emit() < 0) {
                ppnet_uip_poll_active = 0;
                return ppnet_uip_error;
            }
        } else if (ppnet_uip_frame[12] == 0x08
            && ppnet_uip_frame[13] == 0x06) {
            uip_arp_arpin();
            if (ppnet_uip_emit() < 0) {
                ppnet_uip_poll_active = 0;
                return ppnet_uip_error;
            }
        }
        handled = 1;
    }
    uint64_t now = ppnet_port_now_ms();
    if (now - ppnet_uip_last_periodic >= 500) {
        ppnet_uip_last_periodic = now;
        int32_t index;
        for (index = 0; index < UIP_CONNS; index++) {
            if (uip_conn_active(index)) {
                uip_periodic(index);
                if (uip_len > 0) { uip_arp_out(); }
                if (ppnet_uip_emit() < 0) {
                    ppnet_uip_poll_active = 0;
                    return ppnet_uip_error;
                }
                handled = 1;
            }
        }
    }
    if (now - ppnet_uip_last_arp >= 10000) {
        ppnet_uip_last_arp = now;
        uip_arp_timer();
    }
    ppnet_uip_poll_active = 0;
    return handled;
}

int32_t ppnet_uip_request_close(void) {
    if (!ppnet_uip_session) { return PPNET_C_ESTATE; }
    ppnet_uip_close_requested = 1;
    return 0;
}

void ppnet_uip_abort(void) {
    if (ppnet_uip_connection != 0) {
        ppnet_uip_connection->tcpstateflags = UIP_CLOSED;
    }
    ppnet_uip_connection = 0;
    ppnet_uip_session = 0;
    ppnet_uip_is_connected = 0;
    ppnet_uip_is_closed = 1;
    ppnet_uip_pending_size = 0;
    ppnet_uip_inflight_size = 0;
}

int32_t ppnet_uip_connected(void) { return ppnet_uip_is_connected; }
int32_t ppnet_uip_closed(void) { return ppnet_uip_is_closed; }
int32_t ppnet_uip_timed_out(void) { return ppnet_uip_is_timed_out; }
int32_t ppnet_uip_last_error(void) { return ppnet_uip_error; }
int32_t ppnet_uip_tx_queued(void) {
    return ppnet_uip_pending_size + ppnet_uip_inflight_size;
}
int32_t ppnet_uip_rx_queued(void) {
    if (ppnet_uip_receive_full) { return PPNET_TCP_RECEIVE_CAPACITY; }
    if (ppnet_uip_receive_head >= ppnet_uip_receive_tail) {
        return ppnet_uip_receive_head - ppnet_uip_receive_tail;
    }
    return PPNET_TCP_RECEIVE_CAPACITY - ppnet_uip_receive_tail
        + ppnet_uip_receive_head;
}

int32_t ppnet_uip_contract_selftest(void) {
    uint8_t value = 0xA5;
    ppnet_uip_session = 1;
    ppnet_uip_is_connected = 1;
    ppnet_uip_is_closed = 0;
    ppnet_uip_pending_size = 0;
    ppnet_uip_inflight_size = 0;
    int32_t result = ppnet_uip_send((uint64_t)(uintptr_t)&value, 1) == 1
        && ppnet_uip_send(0, 1) == PPNET_C_EINVAL
        && ppnet_uip_send((uint64_t)(uintptr_t)&value,
            PPNET_TCP_QUEUE_CAPACITY) == PPNET_C_ECAPACITY
        && ppnet_uip_receive(0, 1) == PPNET_C_EINVAL;
    ppnet_uip_session = 0;
    ppnet_uip_pending_size = 0;
    ppnet_uip_inflight_size = 0;
    return result;
}
