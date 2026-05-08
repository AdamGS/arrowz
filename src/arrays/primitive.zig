const std = @import("std");
const testing = std.testing;
const Aligned = std.array_list.Aligned;

const DataType = @import("../types.zig").DataType;
const BitBuffer = @import("bit.zig").BitBuffer;

pub const UInt8Array = PrimitiveArray(u8);
pub const UInt16Array = PrimitiveArray(u16);
pub const UInt32Array = PrimitiveArray(u32);
pub const UInt64Array = PrimitiveArray(u64);

pub const Int8Array = PrimitiveArray(i8);
pub const Int16Array = PrimitiveArray(i16);
pub const Int32Array = PrimitiveArray(i32);
pub const Int64Array = PrimitiveArray(i64);

pub const Float16Array = PrimitiveArray(f16);
pub const Float32Array = PrimitiveArray(f32);
pub const Float64Array = PrimitiveArray(f64);

fn PrimitiveArray(comptime T: type) type {
    return struct {
        const Self = @This();

        items: Aligned(T, alignment),
        nulls: ?BitBuffer,

        /// Arrow buffer alignment is either 8 or 64 bytes, for now
        /// this is just hard-coded.
        const alignment = std.mem.Alignment.@"64";

        pub const empty: Self = .{ .items = Aligned(T, alignment).empty, .nulls = null };

        pub fn data_type(_: Self) DataType {
            return switch (T) {
                u8 => DataType.uint8,
                u16 => DataType.uint16,
                u32 => DataType.uint32,
                u64 => DataType.uint64,
                i8 => DataType.int8,
                i16 => DataType.int16,
                i32 => DataType.int32,
                i64 => DataType.int64,
                f16 => DataType.float16,
                f32 => DataType.float32,
                f64 => DataType.float64,
                else => @compileError(
                    "unsupported Primitive array element type: " ++ @typeName(T),
                ),
            };
        }

        pub fn initFromValues(values: []const T, gpa: std.mem.Allocator) !Self {
            var items = try Aligned(T, alignment).initCapacity(gpa, values.len);
            try items.appendSlice(gpa, values);

            return Self{
                .items = items,
                .nulls = null,
            };
        }

        pub fn initWithNulls(values: []const T, nulls: []const bool, gpa: std.mem.Allocator) !Self {
            var items = try Aligned(T, alignment).initCapacity(gpa, values.len);
            try items.appendSlice(gpa, values);

            const validity = try BitBuffer.init(nulls, gpa);

            return Self{
                .items = items,
                .nulls = validity,
            };
        }

        pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
            self.items.deinit(gpa);

            if (self.nulls) |*nulls| {
                nulls.deinit(gpa);
            }
            self.* = undefined;
        }

        pub fn isValid(self: Self, idx: usize) bool {
            if (self.nulls) |nulls| {
                return nulls.isValid(idx);
            } else {
                return true;
            }
        }

        pub fn isNull(self: Self, idx: usize) bool {
            return !self.isValid(idx);
        }

        pub fn len(self: *const Self) usize {
            return self.items.items.len;
        }

        pub fn slice(self: *const Self) *const []T {
            return &self.items.items;
        }

        pub fn value(self: *const Self, idx: usize) T {
            return self.items.items[idx];
        }
    };
}

test "non null array" {
    const array = [_]u64{ 5, 10, 15 };
    var u64_array = try UInt64Array.initFromValues(&array, testing.allocator);
    defer u64_array.deinit(testing.allocator);

    for (0..u64_array.len()) |idx| {
        try testing.expect(u64_array.isValid(idx));
    }

    try testing.expect(u64_array.value(0) == 5);
    try testing.expect(u64_array.value(1) == 10);
    try testing.expect(u64_array.value(2) == 15);
}

test "null array" {
    const array = [_]u64{ 5, 10, 15 };
    const nulls = [_]bool{ true, false, true };

    var u64_array = try UInt64Array.initWithNulls(&array, &nulls, testing.allocator);

    defer u64_array.deinit(testing.allocator);

    try testing.expect(u64_array.isValid(0));
    try testing.expect(u64_array.isNull(1));
    try testing.expect(u64_array.isValid(2));

    try testing.expect(u64_array.value(0) == 5);
    try testing.expect(u64_array.value(1) == 10);
    try testing.expect(u64_array.value(2) == 15);
}

test "empty array" {
    try testing.expectEqual(UInt16Array.empty.len(), 0);
}

test "data_type_u8" {
    try testing.expect(PrimitiveArray(u8).empty.data_type() == DataType.uint8);
}

test "data_type_u16" {
    try testing.expect(PrimitiveArray(u16).empty.data_type() == DataType.uint16);
}
