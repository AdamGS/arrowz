#ifndef NANOARROW_ZIG_H
#define NANOARROW_ZIG_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

struct ArrowArray {
    int64_t length;
    int64_t null_count;
    int64_t offset;
    int64_t n_buffers;
    int64_t n_children;
    const void** buffers;
    struct ArrowArray** children;
    struct ArrowArray* dictionary;
    void (*release)(struct ArrowArray*);
    void* private_data;
};

enum ArrowType {
    NANOARROW_TYPE_UNINITIALIZED = 0,
    NANOARROW_TYPE_NA = 1,
    NANOARROW_TYPE_BOOL = 2,
    NANOARROW_TYPE_UINT8 = 3,
    NANOARROW_TYPE_INT8 = 4,
    NANOARROW_TYPE_UINT16 = 5,
    NANOARROW_TYPE_INT16 = 6,
    NANOARROW_TYPE_UINT32 = 7,
    NANOARROW_TYPE_INT32 = 8,
};

int ArrowArrayInitFromType(
    struct ArrowArray* array,
    enum ArrowType storage_type
);

#ifdef __cplusplus
}
#endif

#endif
