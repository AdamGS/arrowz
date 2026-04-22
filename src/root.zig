//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const Io = std.Io;

pub const array = @import("./array.zig");
pub const bit = @import("buffers/bit.zig");
pub const primitive = @import("buffers/primitive.zig");
pub const data_type = @import("data_type.zig");

test {
    std.testing.refAllDecls(@This());
}
