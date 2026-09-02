#include <stddef.h>

void *memcpy(void *destination, const void *source, size_t size) {
    unsigned char *output = destination;
    const unsigned char *input = source;
    while (size-- != 0) { *output++ = *input++; }
    return destination;
}

void *memmove(void *destination, const void *source, size_t size) {
    unsigned char *output = destination;
    const unsigned char *input = source;
    if (output < input) {
        while (size-- != 0) { *output++ = *input++; }
    } else {
        output += size;
        input += size;
        while (size-- != 0) { *--output = *--input; }
    }
    return destination;
}

void *memset(void *destination, int value, size_t size) {
    unsigned char *output = destination;
    while (size-- != 0) { *output++ = (unsigned char)value; }
    return destination;
}

int memcmp(const void *left, const void *right, size_t size) {
    const unsigned char *a = left;
    const unsigned char *b = right;
    while (size-- != 0) {
        if (*a != *b) { return (int)*a - (int)*b; }
        a++;
        b++;
    }
    return 0;
}

size_t strlen(const char *value) {
    size_t size = 0;
    while (value[size] != '\0') { size++; }
    return size;
}
