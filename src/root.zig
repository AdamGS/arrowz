//! # arrowz
//!
//! This is an attempt at a minimal but correct and hopefully performant implementation of the
//! [Apache Arrow](https://arrow.apache.org/) in-memory data format.

pub const arrays = @import("arrays.zig");
pub const layouts = @import("layouts.zig");
pub const types = @import("types.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
