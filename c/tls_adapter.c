#include <stdint.h>
#include <string.h>

#include "bearssl.h"

typedef struct PpNetWallUtc {
    uint64_t year;
    uint64_t month;
    uint64_t day;
    uint64_t hour;
    uint64_t minute;
    uint64_t second;
} PpNetWallUtc;

extern int32_t ppnet_port_entropy(uint64_t destination, int32_t size);
extern int32_t ppnet_port_wall_utc(uint64_t output);

static br_ssl_client_context ppnet_tls_client;
static br_x509_minimal_context ppnet_tls_x509;
static unsigned char ppnet_tls_buffer[BR_SSL_BUFSIZE_BIDI];
static unsigned char ppnet_tls_seed[48];
static char ppnet_tls_host[254];
static const br_x509_trust_anchor *ppnet_tls_anchors;
static int32_t ppnet_tls_anchor_count;
static int32_t ppnet_tls_active;

static int32_t ppnet_tls_calendar(const PpNetWallUtc *time,
    uint32_t *days, uint32_t *seconds) {
    static const uint16_t before_month[] = {
        0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334
    };
    if (time->year < 2024 || time->year > 9999
        || time->month < 1 || time->month > 12
        || time->day < 1 || time->day > 31 || time->hour > 23
        || time->minute > 59 || time->second > 60) {
        return -1;
    }
    uint64_t year = time->year;
    uint64_t value = 365 * year + (year + 3) / 4 - (year + 99) / 100
        + (year + 399) / 400 + before_month[time->month] + time->day - 1;
    if (time->month > 2
        && ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0)) {
        value++;
    }
    if (value > UINT32_MAX) { return -1; }
    *days = (uint32_t)value;
    *seconds = (uint32_t)(time->hour * 3600
        + time->minute * 60 + time->second);
    return 0;
}

int32_t ppnet_tls_configure_trust(uint64_t anchors, int32_t count) {
    if (ppnet_tls_active || anchors == 0 || count < 1 || count > 32) {
        return -1;
    }
    ppnet_tls_anchors = (const br_x509_trust_anchor *)(uintptr_t)anchors;
    ppnet_tls_anchor_count = count;
    return 0;
}

int32_t ppnet_tls_begin(uint64_t host_address, int32_t host_size) {
    if (ppnet_tls_active || ppnet_tls_anchors == 0 || host_address == 0
        || host_size < 1 || host_size >= (int32_t)sizeof(ppnet_tls_host)) {
        return -1;
    }
    const unsigned char *host = (const unsigned char *)(uintptr_t)host_address;
    int32_t index;
    for (index = 0; index < host_size; index++) {
        unsigned char value = host[index];
        if (!((value >= 'a' && value <= 'z')
            || (value >= 'A' && value <= 'Z')
            || (value >= '0' && value <= '9')
            || value == '.' || value == '-')) {
            return -1;
        }
        ppnet_tls_host[index] = (char)value;
    }
    ppnet_tls_host[host_size] = '\0';
    PpNetWallUtc wall;
    uint32_t days;
    uint32_t seconds;
    if (ppnet_port_wall_utc((uint64_t)(uintptr_t)&wall) != 0
        || ppnet_tls_calendar(&wall, &days, &seconds) != 0
        || ppnet_port_entropy((uint64_t)(uintptr_t)ppnet_tls_seed,
            sizeof(ppnet_tls_seed)) != (int32_t)sizeof(ppnet_tls_seed)) {
        return -2;
    }
    br_ssl_client_init_full(&ppnet_tls_client, &ppnet_tls_x509,
        ppnet_tls_anchors, (size_t)ppnet_tls_anchor_count);
    br_ssl_engine_set_versions(&ppnet_tls_client.eng, BR_TLS12, BR_TLS12);
    br_x509_minimal_set_time(&ppnet_tls_x509, days, seconds);
    br_ssl_engine_set_buffer(&ppnet_tls_client.eng, ppnet_tls_buffer,
        sizeof(ppnet_tls_buffer), 1);
    br_ssl_engine_inject_entropy(&ppnet_tls_client.eng,
        ppnet_tls_seed, sizeof(ppnet_tls_seed));
    memset(ppnet_tls_seed, 0, sizeof(ppnet_tls_seed));
    if (!br_ssl_client_reset(&ppnet_tls_client, ppnet_tls_host, 0)) {
        return -3;
    }
    ppnet_tls_active = 1;
    return 0;
}

int32_t ppnet_tls_state(void) {
    if (!ppnet_tls_active) { return 0; }
    return br_ssl_engine_current_state(&ppnet_tls_client.eng);
}

uint64_t ppnet_tls_send_record(int32_t *size) {
    size_t value = 0;
    unsigned char *buffer = br_ssl_engine_sendrec_buf(
        &ppnet_tls_client.eng, &value);
    if (size == 0 || value > INT32_MAX) { return 0; }
    *size = (int32_t)value;
    return (uint64_t)(uintptr_t)buffer;
}

void ppnet_tls_send_record_ack(int32_t size) {
    br_ssl_engine_sendrec_ack(&ppnet_tls_client.eng, (size_t)size);
}

uint64_t ppnet_tls_receive_record(int32_t *capacity) {
    size_t value = 0;
    unsigned char *buffer = br_ssl_engine_recvrec_buf(
        &ppnet_tls_client.eng, &value);
    if (capacity == 0 || value > INT32_MAX) { return 0; }
    *capacity = (int32_t)value;
    return (uint64_t)(uintptr_t)buffer;
}

void ppnet_tls_receive_record_ack(int32_t size) {
    br_ssl_engine_recvrec_ack(&ppnet_tls_client.eng, (size_t)size);
}

uint64_t ppnet_tls_send_application(int32_t *capacity) {
    size_t value = 0;
    unsigned char *buffer = br_ssl_engine_sendapp_buf(
        &ppnet_tls_client.eng, &value);
    if (capacity == 0 || value > INT32_MAX) { return 0; }
    *capacity = (int32_t)value;
    return (uint64_t)(uintptr_t)buffer;
}

void ppnet_tls_send_application_ack(int32_t size) {
    br_ssl_engine_sendapp_ack(&ppnet_tls_client.eng, (size_t)size);
}

uint64_t ppnet_tls_receive_application(int32_t *size) {
    size_t value = 0;
    unsigned char *buffer = br_ssl_engine_recvapp_buf(
        &ppnet_tls_client.eng, &value);
    if (size == 0 || value > INT32_MAX) { return 0; }
    *size = (int32_t)value;
    return (uint64_t)(uintptr_t)buffer;
}

void ppnet_tls_receive_application_ack(int32_t size) {
    br_ssl_engine_recvapp_ack(&ppnet_tls_client.eng, (size_t)size);
}

void ppnet_tls_flush(void) {
    br_ssl_engine_flush(&ppnet_tls_client.eng, 1);
}

int32_t ppnet_tls_last_error(void) {
    return br_ssl_engine_last_error(&ppnet_tls_client.eng);
}

void ppnet_tls_end(void) {
    memset(&ppnet_tls_client, 0, sizeof(ppnet_tls_client));
    memset(&ppnet_tls_x509, 0, sizeof(ppnet_tls_x509));
    memset(ppnet_tls_buffer, 0, sizeof(ppnet_tls_buffer));
    memset(ppnet_tls_host, 0, sizeof(ppnet_tls_host));
    ppnet_tls_active = 0;
}
