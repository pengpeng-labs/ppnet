#include <stdint.h>
#include "bearssl.h"
#include "trust_anchors.c"

uint64_t ppnet_test_trust_anchors(void) {
    return (uint64_t)(uintptr_t)TAs;
}

int32_t ppnet_test_trust_anchor_count(void) { return TAs_NUM; }
