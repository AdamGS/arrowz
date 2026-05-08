const primitive = @import("../layouts/primitive.zig");

pub const UInt8Array = primitive.Primitive(u8);
pub const UInt16Array = primitive.Primitive(u16);
pub const UInt32Array = primitive.Primitive(u32);
pub const UInt64Array = primitive.Primitive(u64);

pub const Int8Array = primitive.Primitive(i8);
pub const Int16Array = primitive.Primitive(i16);
pub const Int32Array = primitive.Primitive(i32);
pub const Int64Array = primitive.Primitive(i64);

pub const Float16Array = primitive.Primitive(f16);
pub const Float32Array = primitive.Primitive(f32);
pub const Float64Array = primitive.Primitive(f64);
