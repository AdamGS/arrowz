//! Defining the arrow type system:
//!
//! Spec: https://arrow.apache.org/docs/format/Columnar.html#data-types

const std = @import("std");

pub const DataType = enum {
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
    binary,
    large_binary,
    binary_view,
    utf8,
    large_utf8,
    utf8view,
};

pub const StringType = struct {
    fn validate(input: []const u8) bool {
        return std.unicode.utf8ValidateSlice(input);
    }
};

pub const BinaryType = struct {
    fn validate(_: []const u8) bool {
        return true;
    }
};

// This is a place holder for a type system that is much closer
// to the literal spec: https://arrow.apache.org/docs/format/Columnar.html#data-types
// I don't know if its a good idea, but the existing one does miss types like list or decimal
// that require more complex parameters or even nested types.
//
// const IntType = struct {
//     width: u6,
//     is_signed: bool,
// };
//
// const DataType2 = union(enum) { null_, int: IntType };
