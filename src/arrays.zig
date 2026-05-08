pub const primitive = @import("arrays/primitive.zig");
pub const UInt8Array = primitive.UInt8Array;
pub const UInt16Array = primitive.UInt16Array;
pub const UInt32Array = primitive.UInt32Array;
pub const UInt64Array = primitive.UInt64Array;
pub const Int8Array = primitive.Int8Array;
pub const Int16Array = primitive.Int16Array;
pub const Int32Array = primitive.Int32Array;
pub const Int64Array = primitive.Int64Array;
pub const Float16Array = primitive.Float16Array;
pub const Float32Array = primitive.Float32Array;
pub const Float64Array = primitive.Float64Array;

test {
    @import("std").testing.refAllDecls(@This());
}
