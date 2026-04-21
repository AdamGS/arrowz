const std = @import("std");
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

const bits = @import("bit");

pub const UInt8Array = PrimitiveArray(u8);
pub const UInt16Array = PrimitiveArray(u16);
pub const UInt32Array = PrimitiveArray(u32);
pub const UInt64Array = PrimitiveArray(u64);

pub const Int8Array = PrimitiveArray(i8);
pub const Int16Array = PrimitiveArray(i16);
pub const Int32Array = PrimitiveArray(i32);
pub const Int64Array = PrimitiveArray(i64);

fn PrimitiveArray(comptime T: type) type {
    return struct {
        const Self = @This();

        items: std.ArrayList(T),
        nulls: ?std.bit_set.DynamicBitSet,

        pub fn initFromValues(values: []const T, gpa: std.mem.Allocator) !Self {
            var items = try std.ArrayList(T).initCapacity(gpa, values.len);
            try items.appendSlice(gpa, values);

            return Self{
                .items = items,
                .nulls = null,
            };
        }

        pub fn deinit(self: Self, gpa: std.mem.Allocator) void {
            self.items.deinit(gpa);
        }

        pub fn isValid(self: Self, idx: usize) bool {
            if (self.nulls) |nulls| {
                return nulls.isSet(idx);
            } else {
                return true;
            }
        }

        pub fn len(self: *const Self) usize {
            return self.items.items.len;
        }

        pub fn slice(self: *const Self) []T {
            return self.items.items;
        }

        pub fn value(self: *const Self, idx: usize) T {
            return self.items.items[idx];
        }
    };
}

test "non null array" {
    const array = [_]u64{ 5, 10, 15 };
    const u64_array = try UInt64Array.initFromValues(&array, test_allocator);
    defer u64_array.deinit(test_allocator);

    for (0..u64_array.len()) |idx| {
        try expect(u64_array.isValid(idx));
    }

    try expect(u64_array.value(0) == 5);
    try expect(u64_array.value(1) == 10);
    try expect(u64_array.value(2) == 15);
}
