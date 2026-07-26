// test/include/nanoarrow_zig.c
#include <nanoarrow/nanoarrow.h>
#include "nanoarrow_zig.h"

const char* NanoarrowZigTypeString(enum ArrowType storage_type) {
    return ArrowTypeString(storage_type);
}
