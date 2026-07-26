#ifndef NANOARROW_ZIG_H
#define NANOARROW_ZIG_H

#include <nanoarrow/common/inline_types.h>

const char* NanoarrowZigTypeString(enum ArrowType storage_type);

ArrowErrorCode ArrowSchemaInitFromType(struct ArrowSchema* schema, enum ArrowType type);
ArrowErrorCode ArrowSchemaSetTypeStruct(struct ArrowSchema* schema, int64_t n_children);
ArrowErrorCode ArrowArrayInitFromType(struct ArrowArray* array, enum ArrowType type);

#endif
