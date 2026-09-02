#ifndef PPNET_UIP_CONF_H
#define PPNET_UIP_CONF_H

#include <stdint.h>

typedef uint8_t u8_t;
typedef uint16_t u16_t;
typedef unsigned short uip_stats_t;
typedef struct { unsigned char unused; } uip_tcp_appstate_t;
typedef struct { unsigned char unused; } uip_udp_appstate_t;

void ppnet_uip_appcall(void);
#define UIP_APPCALL ppnet_uip_appcall

#define UIP_CONF_IPV6 0
#define UIP_CONF_BUFFER_SIZE 1526
#define UIP_CONF_RECEIVE_WINDOW 2920
#define UIP_CONF_MAX_CONNECTIONS 1
#define UIP_CONF_MAX_LISTENPORTS 0
#define UIP_CONF_UDP 0
#define UIP_CONF_LLH_LEN 14
#define UIP_CONF_BYTE_ORDER UIP_LITTLE_ENDIAN
#define UIP_CONF_LOGGING 0
#define UIP_CONF_STATISTICS 0

#endif
