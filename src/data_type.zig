//! Defining the arrow type system:
//!
//! Spec: https://arrow.apache.org/docs/format/Columnar.html#data-types

const DataType = enum {
    null_,
    boolean,
    int8,
    int16,
    int32,
    int64,
    uint8,
    uint16,
    uint32,
    uint64,
    float16,
    float32,
    float64,
    utf8,
    large_utf8,
    utf8view,
};
