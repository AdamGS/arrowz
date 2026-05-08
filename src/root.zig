//! # arrowz
//!
//! This is an attempt at a minimal but correct and hopefully performant implementation of the
//! [Apache Arrow](https://arrow.apache.org/) in-memory data format.

pub const bit = @import("arrays/bit.zig");
pub const primitive = @import("arrays/primitive.zig");
pub const types = @import("types.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
