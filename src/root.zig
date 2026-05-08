//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const Io = std.Io;

pub const bit = @import("arrays/bit.zig");
pub const primitive = @import("arrays/primitive.zig");
pub const types = @import("types.zig");

test {
    std.testing.refAllDecls(@This());
}
