//! By convention, root.zig is the root source file when making a library.

pub const bit = @import("arrays/bit.zig");
pub const primitive = @import("arrays/primitive.zig");
pub const types = @import("types.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
